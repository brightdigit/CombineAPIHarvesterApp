import Combine
import CoreLocation
import SwiftUI

extension CLAuthorizationStatus: CustomStringConvertible {
  public var description: String {
    switch self {
    case .authorizedAlways:
      return "Always Authorized"
    case .authorizedWhenInUse:
      return "Authorized When In Use"
    case .denied:
      return "Denied"
    case .notDetermined:
      return "Not Determined"
    case .restricted:
      return "Restricted"
    @unknown default:
      return "🤷‍♂️"
    }
  }
}

struct LocationView: View {
  @EnvironmentObject var locationObject: CoreLocationObject
  var body: some View {
    VStack {
      Text("\(locationObject.authorizationStatus.description)").onTapGesture {
        self.locationObject.authorize()
      }
      // use Optional.map to hide the Text if there's no location
      self.locationObject.location.map {
        Text($0.description)
      }

//      self.locationObject.heading.map {
//        Text("\($0)")
//      }
    }
  }
}

struct LocationView_Previews: PreviewProvider {
  static var previews: some View {
    LocationView()
  }
}
