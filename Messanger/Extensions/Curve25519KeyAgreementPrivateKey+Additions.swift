import Foundation
import CryptoKit

extension Curve25519.KeyAgreement.PrivateKey: GenericPasswordConvertible {
    public var description: String { rawRepresentation.hex }
}
