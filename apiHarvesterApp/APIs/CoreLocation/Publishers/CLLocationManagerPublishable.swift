import Combine
import CoreLocation
import SwiftUI

protocol CLLocationManagerPublishableDelegate: CLLocationManagerDelegate {
  func authorizationPublisher() -> AnyPublisher<CLAuthorizationStatus, Never>
  func locationPublisher() -> AnyPublisher<[CLLocation], Error>
  func headingPublisher() -> AnyPublisher<CLHeading?, Never>
}

class CLLocationManagerPublishable: NSObject, CLLocationManagerPublishableDelegate {
  let authorizationSubject = CurrentValueSubject<CLAuthorizationStatus?, Never>(nil)

  let locationSubject = CurrentValueSubject<[CLLocation], Error>([CLLocation]())

  let headingSubject = CurrentValueSubject<CLHeading?, Never>(nil)

  func authorizationPublisher() -> AnyPublisher<CLAuthorizationStatus, Never> {
    return Just(CLLocationManager.authorizationStatus()).merge(with: authorizationSubject.compactMap { $0 }).eraseToAnyPublisher()
  }

  func locationPublisher() -> AnyPublisher<[CLLocation], Error> {
    return locationSubject.eraseToAnyPublisher()
  }

  func headingPublisher() -> AnyPublisher<CLHeading?, Never> {
    return headingSubject.eraseToAnyPublisher()
  }

  func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    locationSubject.send(locations)
  }

  func locationManager(_: CLLocationManager, didFailWithError error: Error) {
    locationSubject.send(completion: .failure(error))
  }

  func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    authorizationSubject.send(status)
  }

  func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    headingSubject.send(newHeading)
  }
}

extension CLLocationManager {
  func authorizationPublisher() -> AnyPublisher<CLAuthorizationStatus, Never>? {
    return (delegate as? CLLocationManagerPublishableDelegate)?.authorizationPublisher()
  }

  func locationPublisher() -> AnyPublisher<[CLLocation], Error>? {
    guard let delegate = self.delegate as? CLLocationManagerPublishableDelegate else {
      return nil
    }

    return delegate.locationPublisher()
  }
}
