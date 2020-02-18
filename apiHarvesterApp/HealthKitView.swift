import Combine
import HealthKit
import SwiftUI

struct ObservableQueryPublisher: Publisher {
  init(store: HKHealthStore, sampleType: HKSampleType, predicate: NSPredicate? = nil, limit: Int, sortDescriptors: [NSSortDescriptor]? = nil) {
    let value = CurrentValueSubject<[HKSample], Error>([HKSample]())
    let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) { _, samples, error in
      if let error = error {
        value.send(completion: .failure(error))
        // completion()
      } else if let samples = samples {
        value.send(samples)
        // completion()
      }
    }
    let observerQuery: HKObserverQuery
    observerQuery = HKObserverQuery(sampleType: sampleType, predicate: predicate) { _, completion, error in
      if let error = error {
        value.send(completion: Subscribers.Completion<Error>.failure(error))
        completion()
        return
      }

      store.execute(sampleQuery)
    }
    store.execute(observerQuery)
    publisher = value.eraseToAnyPublisher()
    self.observerQuery = observerQuery
    self.sampleQuery = sampleQuery
  }

  func receive<S>(subscriber: S) where S: Subscriber, ObservableQueryPublisher.Failure == S.Failure, ObservableQueryPublisher.Output == S.Input {
    publisher.receive(subscriber: subscriber)
  }

  let observerQuery: HKObserverQuery
  let sampleQuery: HKSampleQuery
  let publisher: AnyPublisher<Output, Failure>
  typealias Output = [HKSample]
  typealias Failure = Error
}

extension HKHealthStore {
  func publisher(toObserveSampleType sampleType: HKSampleType, withPredicate predicate: NSPredicate? = nil, limit: Int, sortBy sortDescriptors: [NSSortDescriptor]? = nil) -> AnyPublisher<[HKSample], Error> {
    let value = CurrentValueSubject<[HKSample], Error>([HKSample]())
    let observerQuery: HKObserverQuery
    observerQuery = HKObserverQuery(sampleType: sampleType, predicate: predicate) { _, completion, error in
      if let error = error {
        value.send(completion: Subscribers.Completion<Error>.failure(error))
        completion()
        return
      }
      let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) { _, samples, error in
        if let error = error {
          value.send(completion: .failure(error))
          completion()
        } else if let samples = samples {
          value.send(samples)
          completion()
        }
      }
      self.execute(sampleQuery)
    }
    execute(observerQuery)
    return value.eraseToAnyPublisher()
  }
}

class HealthKitObject: ObservableObject {
  let store = HKHealthStore()
  // var heartRateObserverQuery: HKObserverQuery!
  var heartRatePublisher: AnyPublisher<[HKSample], Error>!

  var heartRateCancellable: AnyCancellable!

  @Published var error: Error?

  @Published var heartRate: Double?

  init() {
//    heartRateObserverQuery =
//      HKObserverQuery(sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, predicate: nil, updateHandler: observerQuery(_:didUpdate:withError:))

    // store.execute(heartRateObserverQuery)
    let heartRatePublisher = store.publisher(toObserveSampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, withPredicate: nil, limit: 1, sortBy: [.init(key: HKSampleSortIdentifierStartDate, ascending: false)])

    self.heartRatePublisher = heartRatePublisher

    heartRateCancellable = heartRatePublisher.catch { _ in
      Just([HKSample]())
    }.compactMap { $0.first as? HKQuantitySample }.map { $0.quantity.doubleValue(for: .init(from: "count/min")) }.receive(on: DispatchQueue.main).assign(to: \.heartRate, on: self)
  }

//  func observerQuery(_ query: HKObserverQuery, didUpdate completion: @escaping HKObserverQueryCompletionHandler, withError _: Error?) {
//    guard let sampleType = query.objectType as? HKSampleType else {
//      completion()
//      return
//    }
//    let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: 1, sortDescriptors: [.init(key: HKSampleSortIdentifierStartDate, ascending: false)], resultsHandler: self.sampleQuery(_:completedWithResults:andError:))
//    store.execute(sampleQuery)
//    completion()
//  }
//
//  func sampleQuery(_: HKSampleQuery, completedWithResults results: [HKSample]?, andError error: Error?) {
//    print(results, error)
//  }

  func authorize() {
    store.requestAuthorization(toShare: nil, read: Set<HKObjectType>([HKObjectType.quantityType(forIdentifier: .heartRate)!, HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!])) { status, _ in
      DispatchQueue.main.async {
        UserDefaults.standard.healthKitQueried = true
        UserDefaults.standard.healthKitAuthorized = status
      }
    }
  }
}

struct HealthKitView: View {
  @EnvironmentObject var healthKitObject: HealthKitObject
  @State var healthKitQueried: Bool = false
  @State var healthKitAuthorized: Bool = false

  let queriedPublisher = UserDefaults.standard.publisher(for: \.healthKitQueried).eraseToAnyPublisher()
  let authorizedPublisher = UserDefaults.standard.publisher(for: \.healthKitAuthorized).eraseToAnyPublisher()

  var body: some View {
    VStack {
      Toggle(isOn: $healthKitQueried, label: {
        Text("Health Queried")
   }).onReceive(queriedPublisher, perform: {
        self.healthKitQueried = $0
   })
      Toggle(isOn: $healthKitAuthorized, label: {
        Text("Health Authorized")
    }).onReceive(authorizedPublisher, perform: {
        self.healthKitAuthorized = $0
    })
      Group {
        healthKitObject.heartRate.map { Text("\($0)") }
      }
    }
    .disabled(true).padding(20.0).onAppear {
      self.healthKitObject.authorize()
    }
  }
}

struct HealthKitView_Previews: PreviewProvider {
  static var previews: some View {
    HealthKitView()
  }
}
