import Combine
import HealthKit
import SwiftUI

class HealthKitObject: ObservableObject {
  let store = HKHealthStore()
  var heartRatePublisher: AnyPublisher<[HKSample], Error>!

  var heartRateCancellable: AnyCancellable!

  @Published var error: Error?

  @Published var heartRate: Double?

  init() {
    let heartRatePublisher = store.publisher(toObserveSampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, withPredicate: nil, limit: 1, sortBy: [.init(key: HKSampleSortIdentifierStartDate, ascending: false)])

    self.heartRatePublisher = heartRatePublisher

    heartRateCancellable = heartRatePublisher.catch { _ in
      Just([HKSample]())
    }.compactMap { $0.first as? HKQuantitySample }.map { $0.quantity.doubleValue(for: .init(from: "count/min")) }.receive(on: DispatchQueue.main).assign(to: \.heartRate, on: self)
  }

  func authorize() {
    store.requestAuthorization(toShare: nil, read: Set<HKObjectType>([HKObjectType.quantityType(forIdentifier: .heartRate)!, HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!])) { status, _ in
      DispatchQueue.main.async {
        UserDefaults.standard.healthKitQueried = true
        UserDefaults.standard.healthKitAuthorized = status
      }
    }
  }
}
