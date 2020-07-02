import SwiftUI

// @propertyWrapper
// struct UserDefault<Value> {
//  let key: String
//  let defaultValue: Value
//
//  init(wrappedValue value: Value, key: String) {
//    defaultValue = value
//    self.key = key
//  }
//
//  var wrappedValue: Value {
//    get { UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue }
//    nonmutating set { UserDefaults.standard.set(newValue, forKey: key) }
//  }
//
//  var projectedValue: Binding<Value> {
//    Binding<Value>(get: { self.wrappedValue }, set: { newValue in self.wrappedValue = newValue })
//  }
// }
//
public extension UserDefaults {
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

  @objc var cloudKitSubscription: String? {
    get {
      return string(forKey: "cloudKitSubscription")
    }
    set {
      set(newValue, forKey: "cloudKitSubscription")
    }
  }
}
