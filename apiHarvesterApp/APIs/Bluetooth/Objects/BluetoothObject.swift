import CoreBluetooth
import Foundation

protocol BluetoothManagerListenerDelegate {}

class BluetoothManagerListener: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  func centralManagerDidUpdateState(_: CBCentralManager) {}

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData _: [String: Any], rssi _: NSNumber) {
    central.connect(peripheral, options: nil)
  }

  func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices(nil)
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
    guard let services = peripheral.services else {
      return
    }
    for service in services {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
    guard let characteristics = service.characteristics else {
      return
    }
    for characteristic in characteristics {
      peripheral.readValue(for: characteristic)
      peripheral.discoverDescriptors(for: characteristic)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error _: Error?) {
    guard let descriptors = characteristic.descriptors else {
      return
    }
    for descriptor in descriptors {
      peripheral.readValue(for: descriptor)
    }
  }

  func peripheral(_: CBPeripheral, didUpdateValueFor _: CBDescriptor, error _: Error?) {}
}

class BluetoothObject: ObservableObject {
  let manager: CBCentralManager
  let listener: BluetoothManagerListener
  init() {
    manager = CBCentralManager()
    listener = BluetoothManagerListener()
    manager.delegate = listener
    manager.scanForPeripherals(withServices: nil, options: nil)
  }
}
