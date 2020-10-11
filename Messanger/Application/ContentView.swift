import SwiftUI
import CoreData
import CryptoKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var keychainModel: KeychainModel
    @State private var isShowingKeyView: Bool = false

    var body: some View {
        NavigationView {
            UsersListView(context: context, keychainModel: keychainModel)
                .navigationTitle("Users")
                .navigationBarItems(
                    leading: Button(action: myKeyButtonAction) {
                        Label("My Key", systemImage: "key")
                    }
                )
                .sheet(isPresented: $isShowingKeyView) {
                    NavigationView {
                        KeyView(keychainViewModel: $keychainModel.viewModel)
                            .navigationTitle("My Key")
                            .navigationBarItems(
                                leading: Button(action: myKeyButtonAction) {
                                    Label("Done", systemImage: "xmark.circle")
                                }
                            )
                    }
                }
        }
    }
    
    private func myKeyButtonAction() { isShowingKeyView.toggle() }
}
