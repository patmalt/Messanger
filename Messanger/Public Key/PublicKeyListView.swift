import SwiftUI
import CoreData
import CryptoKit

struct PublicKeyListView: View {
    let context: NSManagedObjectContext
    let keychainModel: KeychainModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PublicKey.name, ascending: true)],
        animation: .default)
    private var publicKeys: FetchedResults<PublicKey>
    
    var body: some View {
        List {
            ForEach(publicKeys) { key in
                NavigationLink(destination: MessagesListView(publicKey: key, context: context, keychainModel: keychainModel)) {
                    Item(key: key)
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

private extension PublicKeyListView {
    struct Item: View {
        let key: PublicKey
        
        @ViewBuilder
        var body: some View {
            if let name = key.name {
                Text(verbatim: name)
            } else {
                Text("Invalid Key")
            }
        }
    }
}
