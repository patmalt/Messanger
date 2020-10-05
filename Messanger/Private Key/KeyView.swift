import SwiftUI
import CryptoKit

struct KeyView: View {
    @Binding var keychainViewModel: KeychainModel.ViewModel?
    @State var isShowingPrivateKey = false
    
    var body: some View {
        ScrollView {
            VStack {
                HStack(alignment: .top) {
                    Label("Public Key", systemImage: "key")
                    Spacer()
                    Text(publicKeyString).font(.system(.body, design: .monospaced))
                }
                .padding()
                Divider()
                HStack(alignment: .top) {
                    Label("Private Key", systemImage: "key")
                    Spacer()
                    if isShowingPrivateKey {
                        Text(privateKeyString).font(.system(.body, design: .monospaced))
                    } else {
                        Text("Tap to reveal").font(.system(.body, design: .monospaced))
                    }
                }
                .onTapGesture {
                    withAnimation {
                        self.isShowingPrivateKey.toggle()
                    }
                }
                .padding()
            }
        }
    }
    
    private var publicKeyString: String {
        guard let curvePrivateKey = keychainViewModel?.key else { return "No Key 🤒" }
        return curvePrivateKey.publicKey.rawRepresentation.hex
    }
    
    private var privateKeyString: String {
        guard let curvePrivateKey = keychainViewModel?.key else { return "No Key 🤒" }
        return curvePrivateKey.rawRepresentation.hex
    }
}
