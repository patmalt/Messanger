import Foundation
import CryptoKit

struct Crypto {
    private init() {}
    
    static func encrypt<Hash: HashFunction>(secret: Data,
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
    
    static func decrypt<Hash: HashFunction>(combined: Data,
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
    
    static func sharedSecret(privateKey: Curve25519.KeyAgreement.PrivateKey,
                             senderPublicKey publicKey: Curve25519.KeyAgreement.PublicKey) throws -> SharedSecret {
        try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
    }
    
    static func symmetricKey<Hash: HashFunction>(salt: Data,
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
    
    static var salt: Data { Data("Iloveellie<3".utf8) }
    
    static var byteCount: Int { 32 }
}
