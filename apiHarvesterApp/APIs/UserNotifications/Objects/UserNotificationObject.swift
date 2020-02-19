import Combine
import SwiftUI
import UserNotifications

class UserNotificationObject: ObservableObject {
  var token = PassthroughSubject<UUID, Never>()

  var settingsCancellable: AnyCancellable!

  @Published var settings: UNNotificationSettings!

  init() {
    let center = UNUserNotificationCenter.current()
    settingsCancellable = center.settingsPublisher(basedOn: token).receive(on: DispatchQueue.main).assign(to: \.settings, on: self)
  }

  func refresh() {
    token.send(UUID())
  }
}
