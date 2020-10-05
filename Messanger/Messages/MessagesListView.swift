import SwiftUI
import CoreData
import CryptoKit

struct MessagesListView: View {
    let publicKey: PublicKey
    let context: NSManagedObjectContext
    let keychainModel: KeychainModel
    private var messagesRequest: FetchRequest<Message>
    private var messages: FetchedResults<Message> { messagesRequest.wrappedValue }
    @State private var isPresentingNewMessage = false
    
    init(publicKey: PublicKey, context: NSManagedObjectContext, keychainModel: KeychainModel) {
        self.publicKey = publicKey
        self.context = context
        self.keychainModel = keychainModel
        messagesRequest = FetchRequest(
            sortDescriptors:  [NSSortDescriptor(keyPath: \Message.sent, ascending: true)],
            predicate: NSPredicate(format: "sentWith = %@", publicKey),
            animation: .default)
    }
    
    var body: some View {
        List {
            ForEach(messages) { message in
                NavigationLink(destination: MessageView(message: message, context: context, keychainModel: keychainModel)) {
                    Item(message: message)
                }
            }
        }
        .sheet(isPresented: $isPresentingNewMessage) {
            MessageFormView(publicKey: publicKey,
                            context: context,
                            keychainModel: keychainModel,
                            isPresented: $isPresentingNewMessage)
        }
        .navigationTitle("Messages")
        .navigationBarItems(
            trailing: Button(action: { self.isPresentingNewMessage.toggle() }) {
                Label("New", systemImage: "plus")
            }
        )
    }
}

private extension MessagesListView {
    struct Item: View {
        let message: Message
        
        @ViewBuilder
        var body: some View {
            if let date = message.sent {
                Text(verbatim: date.description)
            } else {
                Text("Invalid Message")
            }
        }
    }
}