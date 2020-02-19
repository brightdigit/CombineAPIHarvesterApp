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
      return "?"
    }
  }
}

extension Result where Success == CLLocation, Failure: Error {
  public var text: String {
    switch self {
    case let .success(location):
      return "\(location.coordinate.latitude),\(location.coordinate.longitude)"
    case let .failure(error):
      return error.localizedDescription
    }
  }
}

struct LocationView: View {
  @EnvironmentObject var locationObject: CoreLocationObject
  var body: some View {
    VStack {
      Text("\(locationObject.authorizationStatus.description)").onTapGesture {
        self.locationObject.authorize()
      }.onReceive(self.locationObject.$authorizationStatus) { _ in
        self.locationObject.beginUpdates()
      }

      self.locationObject.location.map {
        Text($0.text)
      }

      self.locationObject.heading.map {
        Text("\($0)")
      }
    }
  }
}

struct LocationView_Previews: PreviewProvider {
  static var previews: some View {
    LocationView()
  }
}
