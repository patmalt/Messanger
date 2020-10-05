import SwiftUI
import CryptoKit

struct KeyView: View {
    @Binding var key: Curve25519.KeyAgreement.PrivateKey?
    @State var isShowingPrivateKey = false
    
    var body: some View {
        ScrollView {
            VStack {
                HStack(alignment: .top) {
                    Label("Public Key", systemImage: "key")
                    Spacer()
                    Text(key?.publicKey.rawRepresentation.hex ?? "No key 🤒").font(.system(.body, design: .monospaced))
                }
                .padding()
                Divider()
                HStack(alignment: .top) {
                    Label("Private Key", systemImage: "key")
                    Spacer()
                    if isShowingPrivateKey {
                        Text(key?.rawRepresentation.hex ?? "No key 🤒").font(.system(.body, design: .monospaced))
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
}
