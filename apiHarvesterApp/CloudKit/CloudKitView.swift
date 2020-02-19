import CloudKit
import Combine
import SwiftUI

class CloudKitObject: ObservableObject {
  init() {
    let database = CKContainer.default().publicCloudDatabase
  }
}

struct CloudKitView: View {
  var body: some View {
    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
  }
}

struct CloudKitView_Previews: PreviewProvider {
  static var previews: some View {
    CloudKitView()
  }
}
