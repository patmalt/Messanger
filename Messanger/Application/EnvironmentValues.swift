import CloudKit
import SwiftUI

private struct MessengerCloudKitContainerEnvironmentKey: EnvironmentKey {
    static let defaultValue: CKContainer = .default()
}

extension EnvironmentValues {
    var cloudKitContainer: CKContainer {
        get { self[MessengerCloudKitContainerEnvironmentKey.self] }
        set { self[MessengerCloudKitContainerEnvironmentKey.self] = newValue }
    }
}
