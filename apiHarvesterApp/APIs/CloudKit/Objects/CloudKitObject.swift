import CloudKit
import Combine
import SwiftUI

extension Array {
  func flatten<Success, Failure: Error>() -> Result<[Success], Failure> where Element == Result<Success, Failure> {
    var array = [Success]()
    for result in self {
      switch result {
      case let .success(value):
        array.append(value)
      case let .failure(error):
        return .failure(error)
      }
    }
    return .success(array)
  }
}

extension Result {
  func catchFailure() -> Failure? {
    guard case let .failure(error) = self else {
      return nil
    }
    return error
  }
}

class CloudKitObject: ObservableObject {
  let database: CKDatabase
  @Published var colors: Result<[Color], Error>?
  init() {
    database = CKContainer(identifier: "iCloud.com.brightdigit.CombineAPIHarvester").publicCloudDatabase

    if let subscriptionID = UserDefaults.standard.cloudKitSubscription {
      verifySubscription(withId: subscriptionID) { _ in }
    } else {
      saveSubscription { _ in }
    }
    beginQuery()
  }

  func verifySubscription(withId subscriptionID: String, _ completed: @escaping ((Error?) -> Void)) {
    database.fetch(withSubscriptionID: subscriptionID) { subscription, error in
      if let error = error {
        completed(error)
        return
      } else if subscription != nil {
        completed(nil)
        return
      } else {
        self.deleteAllSubscriptions { error in
          if let error = error {
            completed(error)
            return
          }
          self.saveSubscription { result in
            completed(result.catchFailure())
            return
          }
        }
      }
    }
  }

  func deleteAllSubscriptions(_ completed: @escaping ((Error?) -> Void)) {
    database.fetchAllSubscriptions { subscriptions, error in
      guard let subscriptions = subscriptions else {
        debugPrint("\(error?.localizedDescription ?? "No Result")")
        completed(error ?? EmptyError())
        return
      }
      let modifyOperation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: subscriptions.map { $0.subscriptionID })
      modifyOperation.modifySubscriptionsCompletionBlock = {
        completed($2)
      }
      self.database.add(modifyOperation)
    }
  }

  func saveSubscription(_ completed: @escaping ((Result<CKSubscription, Error>) -> Void)) {
    let id = UUID()
    let subscription = CKQuerySubscription(recordType: "Color", predicate: NSPredicate(value: true), subscriptionID: id.uuidString, options: CKQuerySubscription.Options.firesOnRecordCreation)
    let notification = CKSubscription.NotificationInfo(alertBody: "There's a new color!")
    subscription.notificationInfo = notification
    database.save(subscription) { subscription, error in
      if let subscription = subscription {
        UserDefaults.standard.cloudKitSubscription = subscription.subscriptionID
      }
      let result = Result(success: subscription, failure: error, fallbackFailure: EmptyError.init)
      completed(result)
    }
  }

  func beginQuery() {
    let query = CKQuery(recordType: "Color", predicate: NSPredicate(value: true))
    query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
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
