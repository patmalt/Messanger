import CloudKit
import Combine

class UserModel: ObservableObject {
    @Published var user: CKUserIdentity?
    
    init(container: CKContainer) {
        container.requestApplicationPermission(.userDiscoverability) { [weak self] (status, error) in
            container.fetchUserRecordID { [weak self] (record, error) in
                guard let record = record else { return }
                container.discoverUserIdentity(withUserRecordID: record) { [weak self] (user, error) in
                    self?.user = user
                }
            }
        }
    }
}
