import SwiftUI
import CoreData
import CryptoKit

struct MessageView: View {
    let message: Message
    let crypto: Crypto
    
    init(message: Message, context: NSManagedObjectContext, keychainModel: KeychainModel) {
        self.message = message
        crypto = Crypto(context: context, keychainModel: keychainModel)
    }
    
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
    
    private var decrypted: String { crypto.decrypt(message: message) }
}
