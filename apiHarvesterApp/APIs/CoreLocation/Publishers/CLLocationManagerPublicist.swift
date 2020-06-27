import Combine
import CoreLocation
import SwiftUI

protocol CLLocationManagerCombineDelegate: CLLocationManagerDelegate {
  func authorizationPublisher() -> AnyPublisher<CLAuthorizationStatus, Never>
  func locationPublisher() -> AnyPublisher<[CLLocation], Never>
  // func headingPublisher() -> AnyPublisher<CLHeading?, Never>
  // func errorPublisher() -> AnyPublisher<Error?, Never>
}

class CLLocationManagerPublicist: NSObject, CLLocationManagerCombineDelegate {
  let authorizationSubject = CurrentValueSubject<CLAuthorizationStatus?, Never>(nil)

  let locationSubject = CurrentValueSubject<[CLLocation], Never>([CLLocation]())

  // let headingSubject = CurrentValueSubject<CLHeading?, Never>(nil)

  // let errorSubject = CurrentValueSubject<Error?, Never>(nil)

  func authorizationPublisher() -> AnyPublisher<CLAuthorizationStatus, Never> {
    return Just(CLLocationManager.authorizationStatus()).merge(with: authorizationSubject.compactMap { $0 }).eraseToAnyPublisher()
  }

  func locationPublisher() -> AnyPublisher<[CLLocation], Never> {
    return locationSubject.eraseToAnyPublisher()
  }

//  func headingPublisher() -> AnyPublisher<CLHeading?, Never> {
//    return headingSubject.eraseToAnyPublisher()
//  }

  func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    locationSubject.send(locations)
    // errorSubject.send(nil)
  }

  func locationManager(_: CLLocationManager, didFailWithError _: Error) {
    // errorSubject.send(error)
  }

  func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    authorizationSubject.send(status)
  }

//  func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//    headingSubject.send(newHeading)
//    errorSubject.send(nil)
//  }

//  func errorPublisher() -> AnyPublisher<Error?, Never> {
//    return errorSubject.eraseToAnyPublisher()
//  }
}
