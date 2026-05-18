import Foundation
import CoreBluetooth

let ARM_SERVICE_UUID = CBUUID(string: "bf77b1ec-80a9-4849-9c64-e6dcd32eb5c9")
let ARM_CHAR_UUID = CBUUID(string: "49b7f353-b294-4023-abb7-1976b9494c2e")

struct DiscoveredArm: Identifiable, Hashable {
    let id: UUID
    let name: String
    var peripheralIdentifier: UUID { id }
}

@MainActor
final class ArmBleController: NSObject, ObservableObject {
    @Published var discovered: [DiscoveredArm] = []
    @Published var scanning: Bool = false

    var onStatus: ((ConnectStatus) -> Void)?

    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var connected: CBPeripheral?
    private var writeChar: CBCharacteristic?

    // Outgoing queue: one byte per second to match the Python client's pacing.
    private var queueBuf: [UInt8] = []
    private var ticker: Timer?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard central.state == .poweredOn else {
            onStatus?(.error("Bluetooth not ready"))
            return
        }
        discovered = []
        peripherals = [:]
        scanning = true
        central.scanForPeripherals(withServices: nil)
    }

    func stopScan() {
        if scanning {
            central.stopScan()
            scanning = false
        }
    }

    func connect(_ id: UUID) {
        stopScan()
        guard let p = peripherals[id] else {
            onStatus?(.error("Unknown peripheral"))
            return
        }
        onStatus?(.connecting)
        connected = p
        p.delegate = self
        central.connect(p)
    }

    func disconnect() {
        stopTicker()
        if let p = connected {
            central.cancelPeripheralConnection(p)
        }
        connected = nil
        writeChar = nil
    }

    /// Queue a gesture byte to be sent. Drops if duplicate of last queued value.
    func queue(gestureIndex: Int) {
        guard gestureIndex >= 0 && gestureIndex < 256 else { return }
        let b = UInt8(gestureIndex)
        if queueBuf.last == b { return }
        queueBuf.append(b)
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.drain() }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
        queueBuf.removeAll()
    }

    private func drain() {
        guard let p = connected, let ch = writeChar, !queueBuf.isEmpty else { return }
        let b = queueBuf.removeFirst()
        p.writeValue(Data([b]), for: ch, type: .withoutResponse)
    }
}

extension ArmBleController: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOff: self.onStatus?(.error("Bluetooth off"))
            case .unauthorized: self.onStatus?(.error("Bluetooth permission denied"))
            case .unsupported: self.onStatus?(.error("Bluetooth unsupported"))
            default: break
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let id = peripheral.identifier
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "Arm \(id.uuidString.prefix(4))"
        Task { @MainActor in
            if self.peripherals[id] == nil {
                self.peripherals[id] = peripheral
                self.discovered.append(DiscoveredArm(id: id, name: name))
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            peripheral.discoverServices([ARM_SERVICE_UUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.onStatus?(.error(error?.localizedDescription ?? "Connect failed"))
            self.connected = nil
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.stopTicker()
            self.connected = nil
            self.writeChar = nil
            self.onStatus?(.disconnected)
        }
    }
}

extension ArmBleController: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard let svc = peripheral.services?.first(where: { $0.uuid == ARM_SERVICE_UUID }) else {
                self.onStatus?(.error("Service not found"))
                return
            }
            peripheral.discoverCharacteristics([ARM_CHAR_UUID], for: svc)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            guard let ch = service.characteristics?.first(where: { $0.uuid == ARM_CHAR_UUID }) else {
                self.onStatus?(.error("Characteristic not found"))
                return
            }
            self.writeChar = ch
            self.onStatus?(.connected)
            self.startTicker()
        }
    }
}
