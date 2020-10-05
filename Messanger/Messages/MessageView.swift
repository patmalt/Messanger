import SwiftUI
import CoreData
import CryptoKit

struct MessageView: View {
    let message: Message
    let context: NSManagedObjectContext
    let keychainModel: KeychainModel
    
    var body: some View {
        ScrollView {
            VStack {
                HStack(alignment: .top) {
                    Label("Encrypted", systemImage: "lock")
                    Spacer()
                    Text(message.body?.hex ?? "No key 🤒").font(.system(.body, design: .monospaced))
                }
                .padding()
                Divider()
                HStack(alignment: .top) {
                    Label("Decrypted", systemImage: "lock.open")
                    Spacer()
                    Text(decrypted).font(.system(.body, design: .monospaced))
                }
                .padding()
            }
        }
        .navigationTitle("Message")
    }
    
    private var decrypted: String {
        guard let data = message.body else {
            return "No body"
        }
        guard let privateKey = keychainModel.key else {
            return "No Private Key"
        }
        guard let rawPublcKey = message.sentWith?.key, let publicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: rawPublcKey) else {
            return "No Public Key"
        }
        guard let decrypted = try? Crypto.decrypt(combined: data,
                                                  salt: Crypto.salt,
                                                  shared: Data(),
                                                  byteCount: Crypto.byteCount,
                                                  hash: SHA512.self,
                                                  privateKey: privateKey,
                                                  senderPublicKey: publicKey) else {
            return "Unable to decrypt"
        }
        guard let value = String(data: decrypted, encoding: .utf8) else {
            return "Unable to create string"
        }
        return value
    }
}
