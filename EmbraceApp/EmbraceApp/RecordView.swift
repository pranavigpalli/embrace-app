import SwiftUI

struct RecordView: View {
    @ObservedObject var state: EmbraceState
    @Environment(\.dismiss) private var dismiss

    @State private var recording = false
    @State private var currentLabel = "--"
    @State private var nextLabel = "--"
    @State private var counterLabel = "--"
    @State private var sampleCount = 0
    @State private var sequenceIndex = 0
    @State private var phase: Phase = .idle
    @State private var stepRemaining = 0
    @State private var phaseTimer: Timer? = nil
    @State private var sampleSubscriptionToken: UUID? = nil
    @State private var memory: [[Double]] = []
    @State private var labels: [Int] = []

    private let countdownSeconds = 3
    private let recordSeconds = 9

    enum Phase { case idle, countdown, recording }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(currentLabel)
                    .font(.system(size: 36, weight: .bold))
                Text(nextLabel)
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text(counterLabel)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Spacer()
                VStack(spacing: 10) {
                    Button(recording ? "Stop" : "Start") {
                        if recording { stop() } else { start() }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    Button("Save CSV") { save() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        .disabled(recording || memory.isEmpty)
                }
                .padding(.bottom, 20)
            }
            .padding(24)
            .navigationTitle("Record MindRove")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { stop(); dismiss() }
                        .disabled(recording)
                }
            }
            .onAppear { hookSamples() }
            .onDisappear {
                phaseTimer?.invalidate()
                phaseTimer = nil
                unhookSamples()
            }
        }
    }

    private func hookSamples() {
        let original = state.mindrove.onSample
        sampleSubscriptionToken = UUID()
        state.mindrove.onSample = { sample in
            original?(sample)
            Task { @MainActor in
                if recording, phase == .recording {
                    memory.append(sample)
                    labels.append(sequenceIndex)
                    sampleCount += 1
                    counterLabel = "Samples: \(sampleCount)"
                }
            }
        }
    }

    private func unhookSamples() {
        // Best-effort: the closure stays installed but won't append once recording=false.
        sampleSubscriptionToken = nil
    }

    private func start() {
        recording = true
        sampleCount = 0
        sequenceIndex = 0
        counterLabel = "--"
        memory.removeAll()
        labels.removeAll()
        beginCountdown()
    }

    private func stop() {
        phaseTimer?.invalidate()
        phaseTimer = nil
        recording = false
        currentLabel = "--"
        nextLabel = "--"
        phase = .idle
    }

    private func save() {
        guard !memory.isEmpty, memory.count == labels.count else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent("emg-\(Int(Date().timeIntervalSince1970 * 1000)).csv")
        var text = ""
        for (i, row) in memory.enumerated() {
            text += row.map { String(format: "%.4f", $0) }.joined(separator: "\t")
            text += "\t\(labels[i])\n"
        }
        try? text.write(to: url, atomically: true, encoding: .utf8)
        counterLabel = "Saved \(memory.count) samples to \(url.lastPathComponent)"
        memory.removeAll()
        labels.removeAll()
    }

    private func beginCountdown() {
        guard recording else { return }
        guard sequenceIndex < GESTURES.count else { stop(); return }
        phase = .countdown
        stepRemaining = countdownSeconds
        currentLabel = "\(stepRemaining)"
        nextLabel = "Next: \(GESTURES[sequenceIndex])"
        startTimer()
    }

    private func beginRecording() {
        phase = .recording
        stepRemaining = recordSeconds
        let next = sequenceIndex + 1 < GESTURES.count ? GESTURES[sequenceIndex + 1] : "(done)"
        currentLabel = "\(GESTURES[sequenceIndex]) \(stepRemaining)"
        nextLabel = "Next: \(next)"
    }

    private func startTimer() {
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            Task { @MainActor in
                guard recording else { t.invalidate(); return }
                stepRemaining -= 1
                if phase == .countdown {
                    if stepRemaining > 0 {
                        currentLabel = "\(stepRemaining)"
                    } else {
                        beginRecording()
                    }
                } else if phase == .recording {
                    if stepRemaining > 0 {
                        currentLabel = "\(GESTURES[sequenceIndex]) \(stepRemaining)"
                    } else {
                        sequenceIndex += 1
                        t.invalidate()
                        beginCountdown()
                    }
                }
            }
        }
    }
}
