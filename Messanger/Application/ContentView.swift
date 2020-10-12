import SwiftUI
import CoreData
import CryptoKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var keychainModel: KeychainModel
    @State private var isShowingKeyView: Bool = false
    @State private var isShowingNewMessageView: Bool = false
    @State private var loadingFontSize: CGFloat = 24

    var body: some View {
        NavigationView {
            if let user = keychainModel.viewModel?.user {
                LandingView(user: user, context: context, keychainModel: keychainModel)
                    .navigationTitle("Messanger")
                    .navigationBarItems(
                        leading: Button(action: myKeyButtonAction) {
                            Label("My Key", systemImage: "key")
                        },
                        trailing: Button(action: newMessageButtonAction) {
                            Label("New", systemImage: "plus")
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
                    .sheet(isPresented: $isShowingNewMessageView) {
                        NavigationView {
                            MessageFormView(context: context,
                                            keychainModel: keychainModel,
                                            isPresented: $isShowingNewMessageView)
                        }
                    }
            } else {
                Text("Loading...")
                    .animatableSystemFont(size: loadingFontSize)
                    .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                        withAnimation {
                            guard loadingFontSize < 60 else { loadingFontSize = 24 ; return }
                            loadingFontSize += 1
                        }
                    }
            }
        }
    }
    
    private func myKeyButtonAction() { isShowingKeyView.toggle() }
    
    private func newMessageButtonAction() { isShowingNewMessageView.toggle() }
}
