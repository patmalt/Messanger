import SwiftUI
import CoreData
import CryptoKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var keychainModel: KeychainModel
    @State private var isShowingKeyView: Bool = false

    var body: some View {
        NavigationView {
            PublicKeyListView(context: context, keychainModel: keychainModel)
                .navigationTitle("Public Keys")
                .navigationBarItems(
                    leading: Button(action: myKeyButtonAction) {
                        Label("My Key", systemImage: "key")
                    }
                )
                .sheet(isPresented: $isShowingKeyView) {
                    NavigationView {
                        KeyView(key: $keychainModel.key)
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
