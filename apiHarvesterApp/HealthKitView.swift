import HealthKit
import SwiftUI

class HealthKitObject: ObservableObject {
  let store = HKHealthStore()
  var heartRateObserverQuery: HKObserverQuery!

  @Published var error: Error?

  init() {
    heartRateObserverQuery =
      HKObserverQuery(sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, predicate: nil, updateHandler: observerQuery(_:didUpdate:withError:))

    store.execute(heartRateObserverQuery)
  }

  func observerQuery(_ query: HKObserverQuery, didUpdate completion: @escaping HKObserverQueryCompletionHandler, withError _: Error?) {
    guard let sampleType = query.objectType as? HKSampleType else {
      completion()
      return
    }
    let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: 1, sortDescriptors: [.init(key: HKSampleSortIdentifierStartDate, ascending: false)], resultsHandler: self.sampleQuery(_:completedWithResults:andError:))
    store.execute(sampleQuery)
    completion()
  }

  func sampleQuery(_: HKSampleQuery, completedWithResults results: [HKSample]?, andError error: Error?) {
    print(results, error)
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
