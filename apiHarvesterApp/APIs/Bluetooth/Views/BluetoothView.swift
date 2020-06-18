import SwiftUI

struct BluetoothView: View {
  @EnvironmentObject var object: BluetoothObject
  var body: some View {
    List(object.devices.values) { device in
      Text(device.id.uuidString)
    }
  }
}

struct BluetoothView_Previews: PreviewProvider {
  static var previews: some View {
    BluetoothView()
  }
}
