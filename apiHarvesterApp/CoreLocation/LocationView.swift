import Combine
import CoreLocation
import SwiftUI

public struct TimestampedError: Error {
  let error: Error
  let timestamp: Date

  init(_ error: Error, timestamp: Date? = nil) {
    self.error = error
    self.timestamp = timestamp ?? Date()
  }

  var localizedDescription: String {
    return error.localizedDescription
  }
}

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

extension Result: Identifiable where Success == CLLocation, Failure == TimestampedError {
  public var id: Date {
    switch self {
    case let .success(location):
      return location.timestamp
    case let .failure(error):
      return error.timestamp
    }
  }

  public var text: String {
    switch self {
    case let .success(location):
      return "\(location.coordinate.latitude),\(location.coordinate.longitude)"
    case let .failure(error):
      return error.localizedDescription
    }
  }
}

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

class CoreLocationObject: ObservableObject {
  let manager: CLLocationManager
  let publishable: CLLocationManagerPublishable

  @Published var authorizationStatus = CLAuthorizationStatus.notDetermined
  @Published var location: Result<CLLocation, TimestampedError>?
  @Published var heading: CLHeading? = nil

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
      Just(Result.failure(TimestampedError($0)))
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
