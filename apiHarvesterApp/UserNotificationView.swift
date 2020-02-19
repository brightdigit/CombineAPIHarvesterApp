import Combine
import SwiftUI
import UserNotifications

extension UNUserNotificationCenter {
  func settingsPublisher<PublisherType: Publisher>(basedOn publisher: PublisherType) -> AnyPublisher<UNNotificationSettings, Never> where PublisherType.Failure == Never {
    return publisher.flatMap {
      _ in
      Future {
        completion in
        self.getNotificationSettings {
          completion(.success($0))
        }
      }
    }.eraseToAnyPublisher()
  }
}

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

struct UserNotificationView: View {
  @EnvironmentObject var userNotificationCenter: UserNotificationObject

  var body: some View {
    userNotificationCenter.settings.map { settings in
      Text("\(settings.authorizationStatus.rawValue)")
    }
  }
}

struct UserNotificationView_Previews: PreviewProvider {
  static var previews: some View {
    UserNotificationView()
  }
}
