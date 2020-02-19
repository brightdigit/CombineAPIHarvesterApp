import SwiftUI

struct ContentView: View {
  var body: some View {
    TabView {
      UserDefaultsView().tabItem {
        VStack {
          Image(systemName: "person.crop.circle.fill")
          Text("UserDefaults")
        }
      }.tag(1)
      HealthKitView().tabItem {
        VStack {
          Image(systemName: "suit.heart.fill")
          Text("HealthKit")
        }
      }.tag(2)
      LocationView().tabItem {
        VStack {
          Image(systemName: "mappin")
          Text("Location")
        }
      }.tag(3)
      CloudKitView().tabItem {
        VStack {
          Image(systemName: "cloud.fill")
          Text("CloudKit")
        }
      }.tag(4)
      UserNotificationView().tabItem {
        VStack {
          Image(systemName: "bubble.left.fill")
          Text("Notifications")
        }
      }.tag(5)
//        HealthKitView().tabItem {
//          VStack{
//            Image(systemName: "chevron.left.slash.chevron.right")
//            Text("XML")
//          }
//        }.tag(0)
//        HealthKitView().tabItem {
//          VStack{
//            Image(systemName: "cube.box.fill")
//            Text("Core Data")
//          }
//        }.tag(0)
//        HealthKitView().tabItem {
//          VStack{
//            Image(systemName: "antenna.radiowaves.left.and.right")
//            Text("Connectivity")
//          }
//        }.tag(0)

//        HealthKitView().tabItem {
//          VStack{
//            Image(systemName: "calendar")
//            Text("EventKit")
//          }
//        }.tag(0)
//        HealthKitView().tabItem {
//          VStack{
//            Image(systemName: "folder.fill")
//            Text("Files")
//          }
//        }.tag(0)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .environmentObject(HealthKitObject()).environmentObject(CoreLocationObject())
      .environmentObject(UserNotificationObject())
  }
}
