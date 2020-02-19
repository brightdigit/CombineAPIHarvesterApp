import CloudKit

class CloudKitObject: ObservableObject {
  init() {
    let database = CKContainer.default().publicCloudDatabase
  }
}
