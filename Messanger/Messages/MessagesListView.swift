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
    private let searchType: SearchType
    
    init?(user: User, context: NSManagedObjectContext, keychainModel: KeychainModel, searchType: SearchType) {
        guard let publicKey = user.publicKey else { return nil }
        self.user = user
        self.publicKey = publicKey
        self.context = context
        self.keychainModel = keychainModel
        messagesRequest = FetchRequest(
            sortDescriptors:  [NSSortDescriptor(keyPath: \Message.sent, ascending: true)],
            predicate: NSPredicate(format: "\(searchType.rawValue) == %@", user),
            animation: .default)
        self.searchType = searchType
    }
    
    var body: some View {
        List {
            ForEach(messages) { message in
                NavigationLink(destination: MessageView(message: message,
                                                        context: context,
                                                        keychainModel: keychainModel,
                                                        searchType: searchType)) {
                    Item(message: message, searchType: searchType)
                }
            }
            .onDelete(perform: deleteItems)
        }
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

extension MessagesListView {
    struct SearchType: Hashable {
        static let inbox = SearchType(rawValue: "to")
        static let outbox = SearchType(rawValue: "from")
        
        public let rawValue: String
        
        private init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

private extension MessagesListView {
    struct Item: View {
        private static let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            formatter.timeZone = TimeZone.current
            return formatter
        }()
        
        let message: Message
        let searchType: MessagesListView.SearchType
        
        @ViewBuilder
        var body: some View {
            VStack(alignment: .leading) {
                if searchType == .outbox {
                    Text("To: \(message.to?.name ?? "Unknown Recipient")").font(.title2)
                } else {
                    Text("From: \(message.from?.name ?? "Unknown Sender")").font(.title2)
                }
                if let date = message.sent {
                    Text(date, formatter: Item.formatter).font(.title3)
                }
            }
        }
    }
}
