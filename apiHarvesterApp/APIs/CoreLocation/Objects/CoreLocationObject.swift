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
    if #available(iOS 14.0, *) {
      authorizationPublisher
        // since this is used in the UI,
        //  it needs to be on the main DispatchQueue
        .receive(on: DispatchQueue.main)
        // store the value in the authorizationStatus property
        .assign(to: &$authorizationStatus)
    } else {
      // Fallback on earlier versions
      authorizationPublisher
        // since this is used in the UI,
        //  it needs to be on the main DispatchQueue
        .receive(on: DispatchQueue.main)
        // store the value in the authorizationStatus property
        .sink(receiveValue: {
          self.authorizationStatus = $0
        })
        // store the cancellable so it be stopped on deinit
        .store(in: &cancellables)
    }

    if #available(iOS 14.0, *) {
      locationPublisher
        // convert the array of CLLocation into a Publisher itself
        .flatMap(Publishers.Sequence.init(sequence:))
        // in order to match the property map to Optional
        .map { $0 as CLLocation? }
        // since this is used in the UI,
        //  it needs to be on the main DispatchQueue
        .receive(on: DispatchQueue.main)
        // store the value in the location property
        .assign(to: &$location)
    } else {
      // Fallback on earlier versions
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
    }
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
