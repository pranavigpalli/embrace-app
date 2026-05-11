import SwiftUI
import Combine

let GESTURES = ["Extend", "Fist", "Flex", "Radial", "Rest", "Ulnar"]
let MAX_SIG: Double = 1e5
let MIN_SIG: Double = -1e5

enum ConnectStatus {
    case disconnected
    case connecting
    case connected
    case error(String)
}

extension ConnectStatus {
    var label: String {
        switch self {
        case .disconnected: return "not connected"
        case .connecting: return "connecting..."
        case .connected: return "connected"
        case .error(let m): return "error: \(m)"
        }
    }
    var color: Color {
        switch self {
        case .connected: return .green
        case .connecting: return .orange
        case .error: return .red
        case .disconnected: return .red
        }
    }
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

enum PredictionStatus { case inactive, dim, lit }

@MainActor
final class EmbraceState: ObservableObject {
    @Published var mindroveStatus: ConnectStatus = .disconnected
    @Published var armStatus: ConnectStatus = .disconnected
    @Published var signalValues: [Double] = Array(repeating: 0, count: 8)
    @Published var signalsEnabled: Bool = false
    @Published var predictionStates: [PredictionStatus] = Array(repeating: .inactive, count: GESTURES.count)
    @Published var showRecordSheet: Bool = false
    @Published var showArmDialog: Bool = false
    @Published var modelLoaded: Bool = false
    @Published var modelName: String = "Tony"

    let mindrove = MindRoveClient()
    let arm = ArmBleController()
    let predictor = GesturePredictor()

    init() {
        modelLoaded = predictor.isLoaded

        mindrove.onStatus = { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                self.mindroveStatus = status
                let connected = status.isConnected
                self.signalsEnabled = connected
                if !connected {
                    for i in 0..<8 { self.signalValues[i] = 0 }
                    for i in 0..<self.predictionStates.count { self.predictionStates[i] = .inactive }
                } else {
                    for i in 0..<self.predictionStates.count { self.predictionStates[i] = .dim }
                }
            }
        }
        mindrove.onSample = { [weak self] sample in
            Task { @MainActor in
                guard let self else { return }
                for i in 0..<8 { self.signalValues[i] = sample[i] }
                if let i = self.predictor.feed(sample) {
                    for k in 0..<self.predictionStates.count {
                        self.predictionStates[k] = (k == i) ? .lit : .dim
                    }
                    self.arm.queue(gestureIndex: i)
                }
            }
        }

        arm.onStatus = { [weak self] status in
            Task { @MainActor in
                self?.armStatus = status
            }
        }
    }
}
