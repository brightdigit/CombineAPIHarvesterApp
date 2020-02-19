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
