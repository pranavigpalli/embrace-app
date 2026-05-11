import Foundation
import Network

// Decoder for the MindRove ArmBand's WiFi protocol.
// Device powers on as an AP at 192.168.4.1 and broadcasts UDP packets on port 4210.
// Phone must be joined to the MindRove Wi-Fi network for any packet to arrive.
//
// Packet types:
//   WUA2 (216 bytes): single sample. Bytes 0..31 = 8 EMG channels as int32 LE,
//                     scaled by EXG_SCALE (0.045 uV/LSB).
//   MES2..MES7: 2 sub-samples, first 2 bytes are COMM_TYPE little-endian int16,
//               EMG block is 8 channels x 3 bytes (24-bit big-endian signed).

private let EXG_SCALE: Double = 0.045
private let WUA2_SIZE = 216
private let SAMPLE_RATE: Double = 500.0

final class MindRoveClient: @unchecked Sendable {
    var onStatus: ((ConnectStatus) -> Void)?
    var onSample: (([Double]) -> Void)?

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "mindrove.udp")

    func start(port: UInt16 = 4210) {
        stop()
        onStatus?(.connecting)
        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            let listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            self.listener = listener

            listener.newConnectionHandler = { [weak self] conn in
                conn.start(queue: self?.queue ?? DispatchQueue.global())
                self?.receive(on: conn)
            }

            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    Task { @MainActor in self.onStatus?(.connected) }
                case .failed(let err):
                    Task { @MainActor in self.onStatus?(.error(err.localizedDescription)) }
                case .cancelled:
                    Task { @MainActor in self.onStatus?(.disconnected) }
                default: break
                }
            }

            listener.start(queue: queue)
        } catch {
            onStatus?(.error(error.localizedDescription))
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func receive(on conn: NWConnection) {
        conn.receiveMessage { [weak self] data, _, _, error in
            guard let self else { return }
            if let data = data, !data.isEmpty {
                self.parse(data)
            }
            if error == nil {
                self.receive(on: conn)
            }
        }
    }

    private func parse(_ data: Data) {
        if data.count == WUA2_SIZE {
            if let sample = Self.parseWUA2(data) {
                Task { @MainActor in self.onSample?(sample) }
            }
            return
        }
        guard data.count >= 2 else { return }
        let commType: Int16 = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Int16.self).littleEndian }
        switch commType {
        case 2, 4, 5, 6, 7:
            // EMG block is at the start of the payload (after 2-byte header), stride 24 per sub-sample.
            let payload = data.advanced(by: 2)
            for sub in 0..<2 {
                if let sample = Self.parseEMG24(payload, baseOffset: sub * 24) {
                    Task { @MainActor in self.onSample?(sample) }
                }
            }
        default:
            return
        }
    }

    /// WUA2: 216 bytes = 54 x int32 LE. First 8 are EMG.
    static func parseWUA2(_ data: Data) -> [Double]? {
        guard data.count >= 32 else { return nil }
        var out = [Double](repeating: 0, count: 8)
        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let p = raw.baseAddress!
            for i in 0..<8 {
                let raw32 = p.load(fromByteOffset: i * 4, as: Int32.self).littleEndian
                out[i] = Double(raw32) * EXG_SCALE
            }
        }
        return out
    }

    /// 8-channel EMG block as 24-bit big-endian signed, scaled by EXG_SCALE.
    static func parseEMG24(_ data: Data, baseOffset: Int) -> [Double]? {
        guard data.count >= baseOffset + 24 else { return nil }
        var out = [Double](repeating: 0, count: 8)
        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            guard let base = raw.baseAddress else { return }
            for i in 0..<8 {
                let p = base.advanced(by: baseOffset + i * 3)
                let b0 = Int32(p.load(fromByteOffset: 0, as: UInt8.self))
                let b1 = Int32(p.load(fromByteOffset: 1, as: UInt8.self))
                let b2 = Int32(p.load(fromByteOffset: 2, as: UInt8.self))
                var v = (b0 << 16) | (b1 << 8) | b2
                if v & 0x800000 != 0 { v -= 0x1000000 }
                out[i] = Double(v) * EXG_SCALE
            }
        }
        return out
    }

    static var sampleRate: Double { SAMPLE_RATE }
}
