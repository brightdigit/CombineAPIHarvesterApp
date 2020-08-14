import SwiftUI

struct UserDefaultsView: View {
  // @State var healthKitAuthorized: Bool = false
  @State var healthKitQueried: Bool = false

  let publisher = UserDefaults.standard.publisher(for: \.healthKitQueried).eraseToAnyPublisher()

  var body: some View {
    HStack {
      Toggle(isOn: $healthKitQueried, label: {
        Text("Health Queried")
      })
    }.onReceive(publisher, perform: {
      self.healthKitQueried = $0
    })
      .disabled(true).onTapGesture {
        print("test")
      }.padding(20.0)
  }
}

struct UserDefaultsView_Previews: PreviewProvider {
  static var previews: some View {
    UserDefaultsView()
  }
}
