import Foundation
import Combine
import CryptoKit
import CloudKit
import CoreData

class KeychainModel: ObservableObject {
    @Published var key: Curve25519.KeyAgreement.PrivateKey?
    private let userModel: UserModel
    private let context: NSManagedObjectContext
    private var disposeBag = Set<AnyCancellable>()
    
    init(container: CKContainer, context: NSManagedObjectContext) {
        userModel = UserModel(container: container)
        self.context = context
        primePrivateKeyOrGenerateIfNecessary()
    }
    
    private func primePrivateKeyOrGenerateIfNecessary() {
        user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                let request: NSFetchRequest<PrivateKey> = PrivateKey.fetchRequest()
                self?.context.perform { [weak self] in
                    if
                        let rawKey = try? self?.context.fetch(request).first?.key,
                        let key = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawKey)
                    {
                        DispatchQueue.main.async {
                            self?.key = key
                        }
                    } else {
                        self?.save(key: Curve25519.KeyAgreement.PrivateKey(),
                                   name: user.nameComponents?.display ?? UUID().uuidString)
                    }
                }
            }
            .store(in: &disposeBag)
    }
    
    private func save(key: Curve25519.KeyAgreement.PrivateKey, name: String) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let newPrivateKey = PrivateKey(context: self.context)
            newPrivateKey.key = key.rawRepresentation
            
            let newPublicKey = PublicKey(context: self.context)
            newPublicKey.name = name
            newPublicKey.key = key.publicKey.rawRepresentation
            newPublicKey.messages = []
            
            do {
                try self.context.save()
                DispatchQueue.main.async {
                    self.key = key
                }
            } catch {
                print(error)
            }
        }
    }
    
    private var user: AnyPublisher<CKUserIdentity, Never> {
        userModel
            .$user
            .compactMap { $0 }
            .prefix(1)
            .eraseToAnyPublisher()
    }
    
    static func save(key: Curve25519.KeyAgreement.PrivateKey, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: key.rawRepresentation
        ] as [String: Any]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { return }
    }
    
    static func key(for account: String) -> (OSStatus, Curve25519.KeyAgreement.PrivateKey?) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: true,
            kSecReturnData: true
        ] as [String: Any]
        var item: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &item) {
        case errSecSuccess:
            guard
                let data = item as? Data,
                let key = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
            else { return (errSecInvalidData, nil) }
            return (errSecSuccess, key)
        case errSecItemNotFound:
            return (errSecItemNotFound, nil)
        case let status:
            return (status, nil)
        }
    }
    
    static func clearKeychain() {
        [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        .forEach { SecItemDelete([kSecClass: $0] as NSDictionary) }
    }
}

private extension PersonNameComponents {
    var display: String {
        let first = givenName
        let last = familyName
        if let first = first {
            if let last = last {
                return "\(first) \(last)"
            } else {
                return "\(first)"
            }
        } else if let last = last {
            if let first = first {
                return "\(first) \(last)"
            } else {
                return "\(last)"
            }
        } else {
            return UUID().uuidString
        }
    }
}