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
        userModel
            .$user
            .compactMap { $0 }
            .flatMap { [weak self] (iCloudUser: CKUserIdentity) -> AnyPublisher<(Curve25519.KeyAgreement.PrivateKey?, CKUserIdentity), Error> in
                guard let self = self, let userRecordId = iCloudUser.userRecordID?.recordName else {
                    return Empty<(Curve25519.KeyAgreement.PrivateKey?, CKUserIdentity), Error>().eraseToAnyPublisher()
                }
                return self.privateKey(matching: userRecordId).map { ($0, iCloudUser) }.eraseToAnyPublisher()
            }
            .flatMap { [weak self] (values: (Curve25519.KeyAgreement.PrivateKey?, CKUserIdentity)) -> AnyPublisher<ViewModel, Error> in
                guard let self = self else {
                    return Empty<ViewModel, Error>().eraseToAnyPublisher()
                }
                let (possiblePrivateKey, iCloudUser) = values
                if let existingKey = possiblePrivateKey, let userRecordId = iCloudUser.userRecordID?.recordName {
                    return self.fetchUser(matching: userRecordId, with: existingKey).eraseToAnyPublisher()
                } else {
                    return self.save(key: Curve25519.KeyAgreement.PrivateKey(), fromICloudUser: iCloudUser).eraseToAnyPublisher()
                }
            }
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { error in
                    print(error)
                    fatalError()
                },
                receiveValue: { [weak self] viewModel in
                    self?.viewModel = viewModel
                }
            )
            .store(in: &self.disposeBag)
    }
    
    private func privateKey(matching userRecordId: String) -> Future<Curve25519.KeyAgreement.PrivateKey?, Error> {
        let privateKeyRequest: NSFetchRequest<PrivateKey> = PrivateKey.fetchRequest()
        privateKeyRequest.predicate = NSPredicate(format: "userRecordId == %@", userRecordId)
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
    
    private func fetchUser(matching recordId: String, with key: Curve25519.KeyAgreement.PrivateKey) -> Future<ViewModel, Error> {
        let userFetchRequest: NSFetchRequest<User> = User.fetchRequest()
        userFetchRequest.predicate = NSPredicate(format: "recordId == %@", recordId)
        return Future { [weak self] promise in
            self?.context.perform { [weak self] in
                guard let self = self else { return }
                do {
                    let users = try self.context.fetch(userFetchRequest)
                    if let user = users.first {
                        promise(.success(ViewModel(key: key, user: user)))
                    } else {
                        promise(.failure(Failure.noCoreDataUser))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    private func save(key: Curve25519.KeyAgreement.PrivateKey, fromICloudUser iCloudUser: CKUserIdentity) -> Future<ViewModel, Error> {
        Future { [weak self] promise in
            self?.context.perform { [weak self] in
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
                
                let newUser = User(context: self.context)
                newUser.recordId = iCloudUser.userRecordID?.recordName
                newUser.messages = []
                newUser.name = name
                newUser.publicKey = newPublicKey
                
                do {
                    try self.context.save()
                    promise(.success(ViewModel(key: key, user: newUser)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    struct ViewModel {
        let key: Curve25519.KeyAgreement.PrivateKey
        let user: User
    }
    
    struct Failure: Error, Hashable {
        static let noCoreDataUser = Failure(rawValue: "noCoreDataUser")
        
        public let rawValue: String
        
        private init(rawValue: String) {
            self.rawValue = rawValue
        }
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
