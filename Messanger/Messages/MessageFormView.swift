import SwiftUI
import CoreData
import CryptoKit

struct MessageFormView: View {
    let context: NSManagedObjectContext
    let keychainModel: KeychainModel
    @Binding var isPresented: Bool
    @State private var text: String = ""
    @State private var userSelection: Int = 0
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
                  animation: .default)
    private var users: FetchedResults<User>
    
    var body: some View {
        Form {
            Section {
                Picker(selection: $userSelection, label: Label("Recipient", systemImage: "person")) {
                    ForEach(0..<users.count) { index in
                        Label(users[index].name ?? "Unknown name", systemImage: "person.fill")
                    }
                }
            }
            Section(header: Label("Message", systemImage: "message")) {
                TextField("Enter your message", text: $text)
            }
            Section {
                Button(action: add) {
                    Text("Save")
                }
            }
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
        let recipient = users[userSelection]
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
