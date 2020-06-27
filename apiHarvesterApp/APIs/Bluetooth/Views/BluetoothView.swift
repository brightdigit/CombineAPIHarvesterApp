import SwiftUI

struct BluetoothView: View {
  @EnvironmentObject var object: BluetoothObject
  var body: some View {
    NavigationView {
      List {
        ForEach(self.object.devices) {
          Text($0.title)
        }
      }
    }
  }
}

struct BluetoothView_Previews: PreviewProvider {
  static var previews: some View {
    BluetoothView()
  }
}
