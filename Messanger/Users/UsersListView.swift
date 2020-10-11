import SwiftUI
import CoreData
import CryptoKit

struct UsersListView: View {
    let context: NSManagedObjectContext
    let keychainModel: KeychainModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        animation: .default)
    private var users: FetchedResults<User>
    
    var body: some View {
        List {
            ForEach(users) { user in
                let destination = MessagesListView(user: user,
                                                   context: context,
                                                   keychainModel: keychainModel)
                NavigationLink(destination: destination) {
                    Item(user: user)
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

private extension UsersListView {
    struct Item: View {
        let user: User
        
        @ViewBuilder
        var body: some View {
            if let name = user.name {
                Text(verbatim: name)
            } else {
                Text("Invalid User Name")
            }
        }
    }
}
