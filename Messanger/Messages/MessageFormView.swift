import SwiftUI
import CoreData
import CryptoKit

struct MessageFormView: View {
    let publicKey: PublicKey
    let context: NSManagedObjectContext
    let keychainModel: KeychainModel
    @Binding var isPresented: Bool
    @State private var text: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter your name", text: $text).padding()
            Spacer()
            Divider()
            Button(action: add) {
                Label("Save", systemImage: "lock.icloud")
            }
            .padding()
        }
        .navigationTitle("New Message")
    }
    
    private func add() {
        let secret = Data(text.utf8)
        if
            let privateKey = keychainModel.key,
            let rawPublicKey = publicKey.key,
            let publicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: rawPublicKey),
            let crypto = try? Crypto.encrypt(secret: secret,
                                             salt: Crypto.salt,
                                             shared: Data(),
                                             byteCount: Crypto.byteCount,
                                             hash: SHA512.self,
                                             senderPrivateKey: privateKey,
                                             publicKey: publicKey)
        {
            context.perform {
                let message = Message(context: context)
                message.body = crypto
                message.sentWith = self.publicKey
                message.sent = Date()
                do {
                    try context.save()
                    isPresented = false
                } catch {
                    print(error)
                }
            }
        }
    }
}
