import SwiftUI

@propertyWrapper
struct UserDefault<Value> {
  let key: String
  let defaultValue: Value

  init(wrappedValue value: Value, key: String) {
    defaultValue = value
    self.key = key
  }

  var wrappedValue: Value {
    get { UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue }
    nonmutating set { UserDefaults.standard.set(newValue, forKey: key) }
  }

  var projectedValue: Binding<Value> {
    Binding<Value>(get: { self.wrappedValue }, set: { newValue in self.wrappedValue = newValue })
  }
}

extension UserDefaults {
  @objc var healthKitQueried: Bool {
    get {
      return bool(forKey: "healthKitQueried")
    }
    set {
      set(newValue, forKey: "healthKitQueried")
    }
  }

  @objc var healthKitAuthorized: Bool {
    get {
      return bool(forKey: "healthKitAuthorized")
    }
    set {
      set(newValue, forKey: "healthKitAuthorized")
    }
  }
}

struct UserDefaultsView: View {
  // @State var healthKitAuthorized: Bool = false
  @State var healthKitQueried: Bool = false

  let publisher = UserDefaults.standard.publisher(for: \.healthKitQueried).eraseToAnyPublisher()
//
//  var body: some View {
//    HStack {
//      Toggle(isOn: $healthKitQueried, label: {
//        Text("Health Queried")
//    })
//    }.disabled(true).onTapGesture {
//      print("test")
//    }.padding(20.0)
//  }

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
