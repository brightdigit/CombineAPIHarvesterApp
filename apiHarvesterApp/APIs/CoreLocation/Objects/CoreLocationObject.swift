import Combine
import CoreLocation
import SwiftUI

class CoreLocationObject: ObservableObject {
  let manager: CLLocationManager
  let publishable: CLLocationManagerPublishable

  @Published var authorizationStatus = CLAuthorizationStatus.notDetermined
  @Published var location: Result<CLLocation, Error>?
  @Published var heading: CLHeading?

  var authorizationCancellable: AnyCancellable!
  var locationsCancellable: AnyCancellable!
  var headingCancellable: AnyCancellable!

  init() {
    let manager = CLLocationManager()
    let delegate = CLLocationManagerPublishable()
    manager.delegate = delegate

    self.manager = manager
    publishable = delegate
    let authorizationPublisher = delegate.authorizationPublisher()
    authorizationCancellable = authorizationPublisher.receive(on: DispatchQueue.main).assign(to: \.authorizationStatus, on: self)

    let locationPublisher = delegate.locationPublisher()

    locationsCancellable = locationPublisher.flatMap {
      Publishers.Sequence(sequence: $0)
    }.map {
      Result.success($0)
    }.catch {
      Just(Result.failure($0))
    }.receive(on: DispatchQueue.main).assign(to: \.location, on: self)

    headingCancellable = delegate.headingPublisher().receive(on: DispatchQueue.main).assign(to: \.heading, on: self)
  }

  func authorize() {
    if CLLocationManager.authorizationStatus() == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
  }

  func beginUpdates() {
    manager.startUpdatingLocation()
    manager.startUpdatingHeading()
  }
}
