import SwiftUI

struct BluetoothView: View {
  @EnvironmentObject var object: BluetoothObject
  var body: some View {
    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
  }
}

struct BluetoothView_Previews: PreviewProvider {
  static var previews: some View {
    BluetoothView()
  }
}
