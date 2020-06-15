import Combine
import SwiftUI
import UserNotifications

struct EmptyError: Error {}

extension Result {
//  init(success: Success, failure: Failure?) {
//    if let failure = failure {
//      self = .failure(failure)
//    } else {
//      self = .success(success)
//    }
//  }

  init(success: Success?, failure: Failure?, fallbackFailure: () -> Failure) {
    if let failure = failure {
      self = .failure(failure)
    } else if let success = success {
      self = .success(success)
    } else {
      self = .failure(fallbackFailure())
    }
  }
}

class UserNotificationObject: ObservableObject {
  let center: UNUserNotificationCenter
  var token = PassthroughSubject<UUID, Never>()
  var requestAuthorizationTrigger = PassthroughSubject<Bool, Never>()

  var settingsCancellable: AnyCancellable!
  var authorizationCancellable: AnyCancellable!
  var triggerCancellable: AnyCancellable!

  @Published var settings: UNNotificationSettings?
  @Published var authorization: Result<Bool, Error>?

  init() {
    let center = UNUserNotificationCenter.current()
    self.center = center
    settingsCancellable = center.settingsPublisher(basedOn: token).map { $0 as UNNotificationSettings? }.receive(on: DispatchQueue.main).assign(to: \.settings, on: self)

    let authRequestPublisher = requestAuthorizationTrigger.filter { $0 }.flatMap { _ in
      Future { completion in
        self.center.requestAuthorization(options: [.alert, .badge, .sound, .announcement]) {
          completion(.success(Result(success: $0, failure: $1, fallbackFailure: { EmptyError() })))
        }
      }
    }

    triggerCancellable = authRequestPublisher.map { _ in UUID() }.subscribe(token)

    authorizationCancellable = authRequestPublisher.map { $0 as Result? }.receive(on: DispatchQueue.main).assign(to: \.authorization, on: self)

    refresh()
  }

  func refresh() {
    token.send(UUID())
  }

  func beginAuthorization() {
    requestAuthorizationTrigger.send(true)
  }
}
