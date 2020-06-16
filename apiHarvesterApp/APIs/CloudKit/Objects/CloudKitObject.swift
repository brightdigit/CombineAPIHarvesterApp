import CloudKit
import Combine
import SwiftUI

class CloudKitObject: ObservableObject {
  let database: CKDatabase
  @Published var colors: Result<[Color], Error>?
  init() {
    database = CKContainer.default().publicCloudDatabase

    let id = UUID()

    if let subscriptionID = UserDefaults.standard.cloudKitSubscription {
      database.fetch(withSubscriptionID: subscriptionID) { _, _ in
      }
    }
    let subscription = CKQuerySubscription(recordType: "Color", predicate: NSPredicate(value: true), subscriptionID: id.uuidString, options: CKQuerySubscription.Options.firesOnRecordCreation)
    let notification = CKSubscription.NotificationInfo(alertBody: "There's a new color!")
    subscription.notificationInfo = notification
    database.save(subscription) { subscription, error in
      let result = Result(success: subscription, failure: error, fallbackFailure: EmptyError.init)
    }
    beginQuery()
  }

  func beginQuery() {
    let query = CKQuery(recordType: "Color", predicate: NSPredicate(value: true))
    query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
    let operation = CKQueryOperation(query: query)
    var items = [Color]()
    operation.resultsLimit = 20
    operation.recordFetchedBlock = { record in
      guard let color = (record["value"] as? Int64).map(Color.init) else {
        return
      }
      items.append(color)
    }
    operation.queryCompletionBlock = { _, error in
      DispatchQueue.main.async {
        self.colors = Result(success: items, failure: error, fallbackFailure: EmptyError.init)
      }
    }
    database.add(operation)
  }
}
