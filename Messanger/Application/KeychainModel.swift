import Foundation
import Combine
import CryptoKit
import CloudKit
import CoreData

class KeychainModel: ObservableObject {
    @Published var viewModel: ViewModel?
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
            .sink { [weak self] iCloudUser in
                guard let self = self else { return }
                guard let userRecordId = iCloudUser.userRecordID?.recordName else { return }
                Publishers
                    .CombineLatest(
                        self.firstPrivateKey,
                        self.user(recordId: userRecordId)
                    )
                    .sink { error in
                        print(error)
                    } receiveValue: { [weak self] values in
                        let (possibleExistingKey, user) = values
                        if let existingKey = possibleExistingKey {
                            DispatchQueue.main.async {
                                self?.viewModel = ViewModel(key: existingKey, user: user)
                            }
                        } else {
                            self?.save(user: user,
                                       andKey: Curve25519.KeyAgreement.PrivateKey(),
                                       fromICloudUser: iCloudUser)
                        }
                    }
                    .store(in: &self.disposeBag)
            }
            .store(in: &disposeBag)
    }
    
    private var firstPrivateKey: Future<Curve25519.KeyAgreement.PrivateKey?, Error> {
        let privateKeyRequest: NSFetchRequest<PrivateKey> = PrivateKey.fetchRequest()
        return Future { [weak self] promise in
            self?.context.perform {
                do {
                    guard let keyObjects = try self?.context.fetch(privateKeyRequest) else {
                        promise(.failure(NSError(domain: "Cannot execute private key fetch request", code: 0, userInfo: nil)))
                        return
                    }
                    if let rawKey = keyObjects.first?.key {
                        guard let existingKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawKey) else {
                            promise(.failure(NSError(domain: "Cannot create key from record", code: 0, userInfo: nil)))
                            return
                        }
                        promise(.success(existingKey))
                    } else {
                        promise(.success(nil))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    private func user(recordId: String) -> Future<User, Error> {
        let userFetchRequest: NSFetchRequest<User> = User.fetchRequest()
        userFetchRequest.predicate = NSPredicate(format: "recordId == %@", recordId)
        return Future { [weak self] promise in
            self?.context.perform { [weak self] in
                guard let self = self else { return }
                do {
                    let users = try self.context.fetch(userFetchRequest)
                    if let user = users.first {
                        promise(.success(user))
                    } else {
                        let newUser = User(context: self.context)
                        newUser.recordId = recordId
                        newUser.messages = []
                        promise(.success(newUser))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    private func save(user: User, andKey key: Curve25519.KeyAgreement.PrivateKey, fromICloudUser iCloudUser: CKUserIdentity) {
        context.perform { [weak self] in
            guard let self = self else { return }
            let name: String
            if let nameComponents = iCloudUser.nameComponents {
                name = PersonNameComponentsFormatter().string(from: nameComponents)
            } else {
                name = UUID().uuidString
            }
            
            let newPrivateKey = PrivateKey(context: self.context)
            newPrivateKey.key = key.rawRepresentation
            newPrivateKey.userRecordId = iCloudUser.userRecordID?.recordName

            let newPublicKey = PublicKey(context: self.context)
            newPublicKey.key = key.publicKey.rawRepresentation

            user.name = name
            user.publicKey = newPublicKey
            
            do {
                try self.context.save()
                DispatchQueue.main.async {
                    self.viewModel = ViewModel(key: key, user: user)
                }
            } catch {
                print(error)
            }
        }
    }
    
    struct ViewModel {
        let key: Curve25519.KeyAgreement.PrivateKey
        let user: User
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
