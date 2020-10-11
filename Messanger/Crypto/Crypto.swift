import Foundation
import CryptoKit
import CoreData

struct Crypto {
    private let context: NSManagedObjectContext
    private let keychainModel: KeychainModel
    
    init(context: NSManagedObjectContext, keychainModel: KeychainModel) {
        self.context = context
        self.keychainModel = keychainModel
    }
    
    func encyrpt(message: String, to user: User, usingPublicKey publicKey: PublicKey, completed: @escaping (Bool) -> ()) {
        let secret = Data(message.utf8)
        context.perform {
            if
                let viewModel = keychainModel.viewModel,
                let rawPublicKey = publicKey.key,
                let curvePublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: rawPublicKey),
                let crypto = try? Crypto.encrypt(secret: secret,
                                                 salt: Crypto.salt,
                                                 shared: Data(),
                                                 byteCount: Crypto.byteCount,
                                                 hash: SHA512.self,
                                                 senderPrivateKey: viewModel.key,
                                                 publicKey: curvePublicKey),
                let senderPublicKeyObjectId = viewModel.user.publicKey?.objectID,
                let senderPublicKey = context.object(with: senderPublicKeyObjectId) as? PublicKey
            {
                let message = Message(context: context)
                message.body = crypto
                message.sent = Date()
                message.to = user
                message.from = senderPublicKey
                do {
                    try context.save()
                    completed(true)
                } catch {
                    print(error)
                    completed(false)
                }
            } else {
                completed(false)
            }
        }
    }
    
    func decrypt(message: Message) -> String {
        var string = String()
        context.performAndWait {
            guard let data = message.body else {
                string = "No body"
                return
            }
            guard let privateKey = keychainModel.viewModel?.key else {
                string = "No Private Key"
                return
            }
            guard let sender = message.from else {
                string = "No Sender"
                return
            }
            guard let rawSenderPublicKey = sender.key else {
                string = "No Sender Public Key"
                return
            }
            guard let curveSentPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: rawSenderPublicKey)
            else {
                string = "No Computed Sent Public Key"
                return
            }
            guard let decrypted = try? Crypto.decrypt(combined: data,
                                                      salt: Crypto.salt,
                                                      shared: Data(),
                                                      byteCount: Crypto.byteCount,
                                                      hash: SHA512.self,
                                                      privateKey: privateKey,
                                                      senderPublicKey: curveSentPublicKey) else {
                string = "Unable to decrypt"
                return
            }
            guard let value = String(data: decrypted, encoding: .utf8) else {
                string = "Unable to create string"
                return
            }
            string = value
        }
        return string
    }
    
    private static func encrypt<Hash: HashFunction>(secret: Data,
                                                    salt: Data,
                                                    shared: Data,
                                                    byteCount: Int,
                                                    hash: Hash.Type,
                                                    senderPrivateKey privateKey: Curve25519.KeyAgreement.PrivateKey,
                                                    publicKey: Curve25519.KeyAgreement.PublicKey) throws -> Data {
        try ChaChaPoly.seal(
            secret,
            using: (
                try symmetricKey(
                    salt: salt,
                    shared: shared,
                    byteCount: byteCount,
                    hash: hash,
                    privateKey: privateKey,
                    senderPublicKey: publicKey)
            )
        )
        .combined
    }
    
    private static func decrypt<Hash: HashFunction>(combined: Data,
                                                    salt: Data,
                                                    shared: Data,
                                                    byteCount: Int,
                                                    hash: Hash.Type,
                                                    privateKey: Curve25519.KeyAgreement.PrivateKey,
                                                    senderPublicKey publicKey: Curve25519.KeyAgreement.PublicKey) throws -> Data {
        try ChaChaPoly.open(
            try ChaChaPoly.SealedBox(combined: combined),
            using: try symmetricKey(
                salt: salt,
                shared: shared,
                byteCount: byteCount,
                hash: hash,
                privateKey: privateKey,
                senderPublicKey: publicKey
            )
        )
    }
    
    private static func sharedSecret(privateKey: Curve25519.KeyAgreement.PrivateKey,
                                     senderPublicKey publicKey: Curve25519.KeyAgreement.PublicKey) throws -> SharedSecret {
        try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
    }
    
    private static func symmetricKey<Hash: HashFunction>(salt: Data,
                                                         shared: Data,
                                                         byteCount: Int,
                                                         hash: Hash.Type,
                                                         privateKey: Curve25519.KeyAgreement.PrivateKey,
                                                         senderPublicKey publicKey: Curve25519.KeyAgreement.PublicKey) throws -> SymmetricKey {
        let symmetricKey = (try sharedSecret(privateKey: privateKey, senderPublicKey: publicKey))
            .hkdfDerivedSymmetricKey(using: hash,
                                     salt: salt,
                                     sharedInfo: shared,
                                     outputByteCount: byteCount)
        return symmetricKey
    }
    
    private static var salt: Data { Data("Iloveellie<3".utf8) }
    
    private static var byteCount: Int { 32 }
}
