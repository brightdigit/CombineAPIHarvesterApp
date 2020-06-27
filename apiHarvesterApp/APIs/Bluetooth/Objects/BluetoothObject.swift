import Combine
import CoreBluetooth
import Foundation

protocol BluetoothManagerListenerDelegate: AnyObject {
  func updatedWith(state: CBManagerState)
  func discoveredDevice(_ device: BluetoothDevice)
  func services(_ result: Result<[BluetoothService], Error>, forPerpheral perpheralIdentifier: UUID)
  func characteristics(_ result: Result<[BluetoothCharacteristic], Error>, forService serviceIdentifier: UUID, withPerpheral perpheralIdentifier: UUID)
  func descriptors(_ result: Result<[BluetoothDescriptor], Error>, forCharacteristic characteristicIdentifier: UUID, withService serviceIdentifier: UUID, andPerpheral perpheralIdentifier: UUID)
  func value(_ result: Result<Data, Error>, forCharacteristic characteristicIdentifier: UUID, withService serviceIdentifier: UUID, andPerpheral perpheralIdentifier: UUID)
  func value(_ result: Result<Any, Error>, forDescriptor descriptorIdentifier: UUID, fromCharacteristic characteristicIdentifier: UUID, withService serviceIdentifier: UUID, andPerpheral perpheralIdentifier: UUID)
}

class BluetoothManagerListener: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  var peripherals = Set<CBPeripheral>()
  weak var delegate: BluetoothManagerListenerDelegate?

  func centralManagerDidUpdateState(_ manager: CBCentralManager) {
    delegate?.updatedWith(state: manager.state)
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
    peripherals.formUnion([peripheral])
    delegate?.discoveredDevice(BluetoothDevice(peripheral: peripheral, rssi: rssi, advertisementData: advertisementData))
    central.connect(peripheral, options: nil)
  }

  func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices(nil)
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    let result = Result(success: peripheral.services, failure: error, fallbackFailure: EmptyError.init).map {
      $0.map(BluetoothService.init)
    }
    delegate?.services(result, forPerpheral: peripheral.identifier)
    guard let services = peripheral.services else {
      return
    }

    for service in services {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    let result = Result(success: service.characteristics, failure: error, fallbackFailure: EmptyError.init).map {
      $0.map(BluetoothCharacteristic.init)
    }
    delegate?.characteristics(result, forService: UUID(cbuuid: service.uuid), withPerpheral: peripheral.identifier)
    guard let characteristics = service.characteristics else {
      return
    }
    for characteristic in characteristics {
      peripheral.readValue(for: characteristic)
      peripheral.discoverDescriptors(for: characteristic)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    let result = Result(success: characteristic.descriptors, failure: error, fallbackFailure: EmptyError.init).map {
      $0.map(BluetoothDescriptor.init)
    }
    delegate?.descriptors(result, forCharacteristic: UUID(cbuuid: characteristic.uuid), withService: UUID(cbuuid: characteristic.service.uuid), andPerpheral: peripheral.identifier)
    guard let descriptors = characteristic.descriptors else {
      return
    }
    for descriptor in descriptors {
      peripheral.readValue(for: descriptor)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    let result = Result(success: characteristic.value, failure: error, fallbackFailure: EmptyError.init)
    delegate?.value(result, forCharacteristic: UUID(cbuuid: characteristic.uuid), withService: UUID(cbuuid: characteristic.service.uuid), andPerpheral: peripheral.identifier)
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    let result = Result(success: descriptor.value, failure: error, fallbackFailure: EmptyError.init)
    delegate?.value(result, forDescriptor: UUID(cbuuid: descriptor.uuid), fromCharacteristic: UUID(cbuuid: descriptor.characteristic.uuid), withService: UUID(cbuuid: descriptor.characteristic.service.uuid), andPerpheral: peripheral.identifier)
  }
}

public extension UUID {
  internal init(data: Data) {
    var bytes = [UInt8](repeating: 0, count: data.count)
    _ = bytes.withUnsafeMutableBufferPointer {
      data.copyBytes(to: $0)
    }
    self = NSUUID(uuidBytes: bytes) as UUID
  }
}

extension UUID {
  init(cbuuid: CBUUID) {
    var bytes = [UInt8](repeating: 0, count: cbuuid.data.count)
    _ = bytes.withUnsafeMutableBufferPointer {
      cbuuid.data.copyBytes(to: $0)
    }
    self = NSUUID(uuidBytes: bytes) as UUID
  }
}

struct BluetoothDescriptor: Identifiable {
  var value: Result<Any, Error>?
  let id: UUID

  init(descriptor: CBDescriptor) {
    id = UUID(cbuuid: descriptor.uuid)
    value = descriptor.value.map {
      .success($0)
    }
  }
}

struct BluetoothCharacteristic: Identifiable {
  var value: Result<Data, Error>?
  var descriptiors: Result<KeyedDictionary<BluetoothDescriptor>, Error>?
  let id: UUID

  init(characteristic: CBCharacteristic) {
    id = UUID(cbuuid: characteristic.uuid)
    value = characteristic.value.map {
      .success($0)
    }
    descriptiors = characteristic.descriptors.map {
      .success(
        KeyedDictionary(
          $0.map {
            BluetoothDescriptor(descriptor: $0)
          }
      ))
    }
  }
}

struct BluetoothService: Identifiable {
  var characteristics: Result<KeyedDictionary<BluetoothCharacteristic>, Error>?
  let id: UUID
  init(service: CBService) {
    id = UUID(cbuuid: service.uuid)
    characteristics = service.characteristics.map {
      .success(
        KeyedDictionary(
          $0.map {
            BluetoothCharacteristic(characteristic: $0)
          }
      ))
    }
  }
}

struct BluetoothDevice: Identifiable {
  public internal(set) var services: Result<KeyedDictionary<BluetoothService>, Error>?
  public private(set) var rssi: Int
  public private(set) var advertisementData: [String: Any]?
  public let id: UUID
  public private(set) var name: String?

  public var title: String {
    return name ?? id.uuidString
  }

  init(peripheral: CBPeripheral, rssi: NSNumber, advertisementData: [String: Any]?) {
    id = peripheral.identifier
    name = peripheral.name
    self.advertisementData = advertisementData
    self.rssi = rssi.intValue

    services = peripheral.services.map {
      .success(
        KeyedDictionary(
          $0.map {
            BluetoothService(service: $0)
          }
      ))
    }
  }
}

struct KeyedDictionary<Value: Identifiable> {
  var values: [Value]
  var dictionary: [Value.ID: Int]

  init(_ values: [Value] = [Value]()) {
    dictionary = .init()
    self.values = .init()

    for value in values {
      replace(value)
    }
  }

  subscript(key: Value.ID) -> Value? {
    get {
      return dictionary[key].map { values[$0] }
    }
    set {
      guard let value = newValue else {
        return
      }
      guard value.id == key else {
        return
      }
      replace(value)
    }
  }

  mutating func replace(_ value: Value) {
    if let index = dictionary[value.id] {
      values[index] = value
    } else {
      values.append(value)
      dictionary[value.id] = values.count - 1
    }
  }
}

extension Result {
  var withSuccess: Success? {
    get {
      return try? get()
    }
    set {
      guard let value = newValue else {
        return
      }
      self = .success(value)
    }
  }
}

class BluetoothObject: ObservableObject, BluetoothManagerListenerDelegate {
  func updatedWith(state: CBManagerState) {
    self.state = state
    if state == .poweredOn {
      manager.scanForPeripherals(withServices: nil, options: nil)
    }
  }

  func discoveredDevice(_ device: BluetoothDevice) {
    directory.replace(device)
    dump(device)
  }

  func services(_ result: Result<[BluetoothService], Error>, forPerpheral perpheralIdentifier: UUID) {
    directory[perpheralIdentifier]?.services = result.map(
      KeyedDictionary.init
    )
  }

  func characteristics(_ result: Result<[BluetoothCharacteristic], Error>, forService serviceIdentifier: UUID, withPerpheral perpheralIdentifier: UUID) {
    directory[perpheralIdentifier]?.services?.withSuccess?[serviceIdentifier]?.characteristics = result.map(KeyedDictionary.init)
  }

  func descriptors(_ result: Result<[BluetoothDescriptor], Error>, forCharacteristic characteristicIdentifier: UUID, withService serviceIdentifier: UUID, andPerpheral perpheralIdentifier: UUID) {
    directory[perpheralIdentifier]?.services?.withSuccess?[serviceIdentifier]?.characteristics?.withSuccess?[characteristicIdentifier]?.descriptiors = result.map(KeyedDictionary.init)
  }

  func value(_ result: Result<Data, Error>, forCharacteristic characteristicIdentifier: UUID, withService serviceIdentifier: UUID, andPerpheral perpheralIdentifier: UUID) {
    directory[perpheralIdentifier]?.services?.withSuccess?[serviceIdentifier]?.characteristics?.withSuccess?[characteristicIdentifier]?.value = result
  }

  func value(_ result: Result<Any, Error>, forDescriptor descriptorIdentifier: UUID, fromCharacteristic characteristicIdentifier: UUID, withService serviceIdentifier: UUID, andPerpheral perpheralIdentifier: UUID) {
    directory[perpheralIdentifier]?.services?.withSuccess?[serviceIdentifier]?.characteristics?.withSuccess?[characteristicIdentifier]?.descriptiors?.withSuccess?[descriptorIdentifier]?.value = result
  }

  let manager: CBCentralManager
  let listener: BluetoothManagerListener

  @Published var state: CBManagerState?

  @Published var directory = KeyedDictionary<BluetoothDevice>()
  @Published var devices = [BluetoothDevice]()

  var cancellables = [AnyCancellable]()
  init() {
    manager = CBCentralManager()
    listener = BluetoothManagerListener()
    manager.delegate = listener
    listener.delegate = self

    $directory.map(\.values).receive(on: DispatchQueue.main).assign(to: \.devices, on: self).store(in: &cancellables)
  }
}
