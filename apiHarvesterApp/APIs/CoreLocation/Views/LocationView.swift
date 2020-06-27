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
  // CLLocationManager is basically a singleton so an EnvironmentObject ObservableObject makes sense
  @EnvironmentObject var locationObject: CoreLocationObject

  var body: some View {
    VStack {
      // use our extension method to display a description of the status
      Text("\(locationObject.authorizationStatus.description)")
        .onTapGesture {
          self.locationObject.authorize()
        }
      // use Optional.map to hide the Text if there's no location
      self.locationObject.location.map {
        Text($0.description)
      }
    }
  }
}

struct LocationView_Previews: PreviewProvider {
  static var previews: some View {
    LocationView()
  }
}
