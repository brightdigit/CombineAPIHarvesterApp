import Combine
import HealthKit
import SwiftUI

struct HealthKitView: View {
  @EnvironmentObject var healthKitObject: HealthKitObject
  @State var healthKitQueried: Bool = false
  @State var healthKitAuthorized: Bool = false

  let queriedPublisher = UserDefaults.standard.publisher(for: \.healthKitQueried).eraseToAnyPublisher()
  let authorizedPublisher = UserDefaults.standard.publisher(for: \.healthKitAuthorized).eraseToAnyPublisher()

  var body: some View {
    VStack {
      Toggle(isOn: $healthKitQueried, label: {
        Text("Health Queried")
      }).onReceive(queriedPublisher, perform: {
        self.healthKitQueried = $0
      })
      Toggle(isOn: $healthKitAuthorized, label: {
        Text("Health Authorized")
      }).onReceive(authorizedPublisher, perform: {
        self.healthKitAuthorized = $0
      })
      HStack {
        Text("Heart Rate")
        Spacer()
        Group {
          healthKitObject.heartRate.map { Text("\($0)") }
        }
      }
    }
    .disabled(true).padding(20.0).onAppear {
      self.healthKitObject.authorize()
    }
  }
}

struct HealthKitView_Previews: PreviewProvider {
  static var previews: some View {
    HealthKitView()
  }
}
