import SwiftUI
import CoreData
import CryptoKit

struct MessageFormView: View {
    let context: NSManagedObjectContext
    let keychainModel: KeychainModel
    @Binding var isPresented: Bool
    @State private var text: String = ""
    @State private var user: Int = 0
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
                  animation: .default)
    private var users: FetchedResults<User>
    
    var body: some View {
        VStack {
            Picker("To", selection: $user) {
                ForEach(users) { (otherUser: User) in
                    Label(otherUser.name ?? "Unknown name", systemImage: "person")
                }
            }
            .pickerStyle(InlinePickerStyle())
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
            .padding([.top, .bottom])
        )
    }
    
    private func doneButtonAction() { isPresented.toggle() }
    
    private func add() {
        let recipient = users[user]
        guard let recipientPublicKey = recipient.publicKey else { return }
        Crypto(
            context: context,
            keychainModel: keychainModel
        )
        .encyrpt(message: text,
                 to: recipient,
                 usingPublicKey: recipientPublicKey) { success in
            guard success else { return }
            isPresented = false
        }
    }
}
