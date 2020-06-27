import Combine
import CoreLocation
import SwiftUI

class CoreLocationObject: ObservableObject {
  let manager: CLLocationManager
  let publishable: CLLocationManagerPublishable

  @Published var authorizationStatus = CLAuthorizationStatus.notDetermined
  @Published var location: CLLocation?
  // @Published var heading: CLHeading?

  var authorizationCancellable: AnyCancellable!
  var locationsCancellable: AnyCancellable!
  var beginUpdatesCancellable: AnyCancellable!
  // var headingCancellable: AnyCancellable!

  init() {
    let manager = CLLocationManager()
    let delegate = CLLocationManagerPublishable()

    manager.delegate = delegate

    self.manager = manager
    publishable = delegate

    let authorizationPublisher = delegate.authorizationPublisher()
    let locationPublisher = delegate.locationPublisher()

    authorizationCancellable = authorizationPublisher.receive(on: DispatchQueue.main).assign(to: \.authorizationStatus, on: self)

    beginUpdatesCancellable = authorizationPublisher.sink(receiveValue: beginUpdates)

    locationsCancellable = locationPublisher.flatMap {
      Publishers.Sequence(sequence: $0)
    }.receive(on: DispatchQueue.main).assign(to: \.location, on: self)

    // headingCancellable = delegate.headingPublisher().receive(on: DispatchQueue.main).assign(to: \.heading, on: self)
  }

  func authorize() {
    if CLLocationManager.authorizationStatus() == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
  }

  fileprivate func beginUpdates(_ authorizationStatus: CLAuthorizationStatus) {
    if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
      manager.startUpdatingLocation()
      manager.startUpdatingHeading()
    }
  }
}
