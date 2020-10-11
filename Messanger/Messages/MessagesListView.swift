import SwiftUI
import CoreData
import CryptoKit

struct MessagesListView: View {
    let user: User
    private let publicKey: PublicKey
    let context: NSManagedObjectContext
    let keychainModel: KeychainModel
    private let messagesRequest: FetchRequest<Message>
    private var messages: FetchedResults<Message> { messagesRequest.wrappedValue }
    @State private var isPresentingNewMessage = false
    
    init?(user: User, context: NSManagedObjectContext, keychainModel: KeychainModel) {
        guard let publicKey = user.publicKey else { return nil }
        self.user = user
        self.publicKey = publicKey
        self.context = context
        self.keychainModel = keychainModel
        messagesRequest = FetchRequest(
            sortDescriptors:  [NSSortDescriptor(keyPath: \Message.sent, ascending: true)],
            predicate: NSPredicate(format: "to == %@", user),
            animation: .default)
    }
    
    var body: some View {
        List {
            ForEach(messages) { message in
                NavigationLink(destination: MessageView(message: message, context: context, keychainModel: keychainModel)) {
                    Item(message: message)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .sheet(isPresented: $isPresentingNewMessage) {
            MessageFormView(user: user,
                            publicKey: publicKey,
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
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            context.perform {
                offsets.map { messages[$0] }.forEach(context.delete)
                do {
                    try context.save()
                } catch {
                    print(error)
                }
            }
        }
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
