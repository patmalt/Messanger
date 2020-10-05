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
        NavigationView {
            VStack {
                TextField("Enter your message", text: $text).padding()
                Spacer()
                Divider()
                Button(action: add) {
                    Label("Save", systemImage: "lock.icloud")
                }
                .padding()
            }
            .navigationTitle("New Message")
            .navigationBarItems(
                trailing: Button(action: doneButtonAction) {
                    Label("Cancel", systemImage: "xmark.circle")
                }
            )
        }
    }
    
    private func doneButtonAction() { isPresented.toggle() }
    
    private func add() {
        Crypto(
            context: context,
            keychainModel: keychainModel
        )
        .encyrpt(message: text, usingPublicKey: publicKey) { success in
            guard success else { return }
            isPresented = false
        }
    }
}
