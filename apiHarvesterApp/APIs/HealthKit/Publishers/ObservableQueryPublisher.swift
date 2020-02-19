import Combine
import HealthKit
import SwiftUI

struct ObservableQueryPublisher: Publisher {
  init(store: HKHealthStore, sampleType: HKSampleType, predicate: NSPredicate? = nil, limit: Int, sortDescriptors: [NSSortDescriptor]? = nil) {
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
      store.execute(sampleQuery)
    }
    store.execute(observerQuery)
    publisher = value.eraseToAnyPublisher()
    self.observerQuery = observerQuery
  }

  func receive<S>(subscriber: S) where S: Subscriber, ObservableQueryPublisher.Failure == S.Failure, ObservableQueryPublisher.Output == S.Input {
    publisher.receive(subscriber: subscriber)
  }

  let observerQuery: HKObserverQuery
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
