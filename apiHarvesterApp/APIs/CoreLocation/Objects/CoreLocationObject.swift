import Combine
import CoreLocation
import SwiftUI

class CoreLocationObject: ObservableObject {
  @Published var authorizationStatus = CLAuthorizationStatus.notDetermined
  @Published var location: CLLocation?

  let manager: CLLocationManager
  let publicist: CLLocationManagerCombineDelegate

  var cancellables = [AnyCancellable]()

  init() {
    let manager = CLLocationManager()
    let publicist = CLLocationManagerPublicist()

    manager.delegate = publicist

    self.manager = manager
    self.publicist = publicist

    let authorizationPublisher = publicist.authorizationPublisher()
    let locationPublisher = publicist.locationPublisher()

    // trigger an update when authorization changes
    authorizationPublisher
      .sink(receiveValue: beginUpdates)
      .store(in: &cancellables)

    // set authorization status when authorization changes
    authorizationPublisher
      // since this is used in the UI,
      //  it needs to be on the main DispatchQueue
      .receive(on: DispatchQueue.main)
      // store the value in the authorizationStatus property
      .assign(to: \.authorizationStatus, on: self)
      // store the cancellable so it be stopped on deinit
      .store(in: &cancellables)

    locationPublisher
      // convert the array of CLLocation into a Publisher itself
      .flatMap(Publishers.Sequence.init(sequence:))
      // in order to match the property map to Optional
      .map { $0 as CLLocation? }
      // since this is used in the UI,
      //  it needs to be on the main DispatchQueue
      .receive(on: DispatchQueue.main)
      // store the value in the location property
      .assign(to: \.location, on: self)
      // store the cancellable so it be stopped on deinit
      .store(in: &cancellables)

    // headingCancellable = delegate.headingPublisher().receive(on: DispatchQueue.main).assign(to: \.heading, on: self)
  }

  func authorize() {
    if CLLocationManager.authorizationStatus() == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
  }

  func beginUpdates(_ authorizationStatus: CLAuthorizationStatus) {
    if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
      manager.startUpdatingLocation()
    }
  }
}
