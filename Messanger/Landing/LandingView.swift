import SwiftUI
import CoreData

struct LandingView: View {
    let user: User
    let context: NSManagedObjectContext
    let keychainModel: KeychainModel
    
    var body: some View {
        Form {
            Section {
                NavigationLink(
                    destination: MessagesListView(user: user,
                                                  context: context,
                                                  keychainModel: keychainModel,
                                                  searchType: .inbox).navigationTitle("Inbox")) {
                    Label("Inbox", systemImage: "envelope")
                }
            }
            Section {
                NavigationLink(destination: MessagesListView(user: user,
                                                             context: context,
                                                             keychainModel: keychainModel,
                                                             searchType: .outbox).navigationTitle("Sent")) {
                    Label("Sent", systemImage: "paperplane")
                }
            }
        }
    }
}
