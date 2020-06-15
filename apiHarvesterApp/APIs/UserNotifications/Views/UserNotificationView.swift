import Combine
import SwiftUI
import UserNotifications

extension UNAuthorizationStatus: CustomStringConvertible {
  public var description: String {
    switch self {
    case .authorized:
      return "Authorized"
    case .denied:
      return "Denied"
    case .notDetermined:
      return "Not Determined"
    case .provisional:
      return "Provisional"
    @unknown default:
      return "Unsupported"
    }
  }
}

extension UNNotificationSetting: CustomStringConvertible {
  public var description: String {
    switch self {
    case .disabled:
      return "disabled"
    case .enabled:
      return "enabled"
    case .notSupported:
      return "notSupported"
    @unknown default:
      return "notSupported"
    }
  }
}

struct UserNotificationView: View {
  @EnvironmentObject var userNotificationCenter: UserNotificationObject

  var body: some View {
    VStack {
      userNotificationCenter.settings.map(self.view)
    }.padding(20.0)
  }

  func view(forSettings settings: UNNotificationSettings) -> some View {
    VStack(alignment: .center, spacing: 8.0) {
      HStack {
        Text("Authorization")
        Spacer()
        Text("\(settings.authorizationStatus.description)")
      }
      HStack {
        Text("Alerts")
        Spacer()
        Text("\(settings.alertSetting.description)")
      }
    }.onTapGesture {
      self.beginAuthorization()
    }
  }

  func beginAuthorization() {
    userNotificationCenter.beginAuthorization()
  }
}

struct UserNotificationView_Previews: PreviewProvider {
  static var previews: some View {
    UserNotificationView().environmentObject(UserNotificationObject())
  }
}
