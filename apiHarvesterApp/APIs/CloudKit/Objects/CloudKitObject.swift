import CloudKit

class CloudKitObject: ObservableObject {
  init() {
    let database = CKContainer.default().publicCloudDatabase

    let id = UUID()

    if let subscriptionID = UserDefaults.standard.cloudKitSubscription {
      database.fetch(withSubscriptionID: subscriptionID) { _, _ in
      }
    }
    let subscription = CKQuerySubscription(recordType: "Color", predicate: NSPredicate(value: true), subscriptionID: id.uuidString, options: CKQuerySubscription.Options.firesOnRecordCreation)
    database.save(subscription) { subscription, error in
      let result = Result(success: subscription, failure: error, fallbackFailure: EmptyError.init)
    }
  }
}
