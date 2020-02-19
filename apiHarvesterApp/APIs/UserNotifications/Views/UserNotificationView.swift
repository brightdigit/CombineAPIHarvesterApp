import Combine
import SwiftUI
import UserNotifications

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
