import Foundation
import CoreML

private let WINDOW: Int = 600
private let CHANNELS: Int = 8

@MainActor
final class GesturePredictor {
    private var model: MLModel?
    private var buffer: [[Double]] = []

    var isLoaded: Bool { model != nil }

    init() {
        loadModel()
    }

    private func loadModel() {
        // Xcode compiles .mlpackage to .mlmodelc next to the app binary.
        if let url = Bundle.main.url(forResource: "EmbraceModel", withExtension: "mlmodelc"),
           let m = try? MLModel(contentsOf: url) {
            self.model = m
            return
        }
        // Fallback: load the uncompiled package and compile on the fly.
        if let url = Bundle.main.url(forResource: "EmbraceModel", withExtension: "mlpackage"),
           let compiled = try? MLModel.compileModel(at: url),
           let m = try? MLModel(contentsOf: compiled) {
            self.model = m
            return
        }
        self.model = nil
    }

    /// Append one EMG sample (8 channels) and run inference when a full 600-sample window is ready.
    /// Returns the predicted gesture index, or nil if the buffer isn't full or the model isn't loaded.
    func feed(_ sample: [Double]) -> Int? {
        guard sample.count == CHANNELS else { return nil }
        buffer.append(sample)
        guard buffer.count >= WINDOW else { return nil }
        let window = Array(buffer.prefix(WINDOW))
        buffer.removeFirst(WINDOW)
        return predict(window: window)
    }

    private func predict(window: [[Double]]) -> Int? {
        guard let model = model else { return nil }
        guard let input = try? MLMultiArray(shape: [1, NSNumber(value: WINDOW), NSNumber(value: CHANNELS)], dataType: .float32) else {
            return nil
        }
        let ptr = input.dataPointer.bindMemory(to: Float32.self, capacity: WINDOW * CHANNELS)
        for t in 0..<WINDOW {
            let row = window[t]
            for c in 0..<CHANNELS {
                ptr[t * CHANNELS + c] = Float32(row[c])
            }
        }
        let provider = try? MLDictionaryFeatureProvider(dictionary: ["input": MLFeatureValue(multiArray: input)])
        guard let provider = provider,
              let out = try? model.prediction(from: provider),
              let logits = out.featureValue(for: "logits")?.multiArrayValue else { return nil }
        let n = logits.count
        var bestIndex = 0
        var bestValue: Float32 = -.infinity
        let lp = logits.dataPointer.bindMemory(to: Float32.self, capacity: n)
        for i in 0..<n {
            if lp[i] > bestValue { bestValue = lp[i]; bestIndex = i }
        }
        return bestIndex
    }
}
