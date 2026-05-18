import SwiftUI

struct RecordView: View {
    @ObservedObject var state: EmbraceState
    @Environment(\.dismiss) private var dismiss

    @State private var recording = false
    @State private var currentLabel = "—"
    @State private var nextLabel = "—"
    @State private var counterLabel = "—"
    @State private var statusLine = "Ready to capture"
    @State private var sampleCount = 0
    @State private var sequenceIndex = 0
    @State private var phase: Phase = .idle
    @State private var stepRemaining = 0
    @State private var stepTotal = 1
    @State private var phaseTimer: Timer? = nil
    @State private var sampleSubscriptionToken: UUID? = nil
    @State private var memory: [[Double]] = []
    @State private var labels: [Int] = []

    private let countdownSeconds = 3
    private let recordSeconds = 9

    enum Phase { case idle, countdown, recording }

    private var phaseLabel: String {
        switch phase {
        case .idle:      return "STANDBY"
        case .countdown: return "GET READY"
        case .recording: return "RECORDING"
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .idle:      return Theme.textTertiary
        case .countdown: return Theme.warning
        case .recording: return Theme.danger
        }
    }

    private var progressFraction: Double {
        guard stepTotal > 0 else { return 0 }
        let elapsed = Double(stepTotal - stepRemaining)
        return min(1, max(0, elapsed / Double(stepTotal)))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 22) {
                    header
                    ringCard
                    statsRow
                    Spacer(minLength: 8)
                    controls
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { hookSamples() }
            .onDisappear {
                phaseTimer?.invalidate()
                phaseTimer = nil
                unhookSamples()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("RECORD")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(Theme.accentGradient)
                Text("MINDROVE CAPTURE SESSION")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(2.2)
                    .foregroundColor(Theme.textTertiary)
            }
            Spacer()
            Button {
                stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle().fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(recording)
            .opacity(recording ? 0.35 : 1.0)
        }
    }

    private var ringCard: some View {
        GlassCard {
            VStack(spacing: 18) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(phaseColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: phaseColor, radius: phase == .recording ? 8 : 0)
                    Text(phaseLabel)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .tracking(2.4)
                        .foregroundColor(phaseColor)
                }

                ZStack {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 14)
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: progressFraction)
                        .stroke(
                            phase == .recording
                                ? AnyShapeStyle(LinearGradient(colors: [Theme.danger, Theme.accent3], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Theme.accentGradient),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 220, height: 220)
                        .animation(.easeInOut(duration: 0.4), value: progressFraction)
                        .shadow(color: phase == .recording ? Theme.danger.opacity(0.5) : Theme.accent.opacity(0.4), radius: 14)

                    VStack(spacing: 6) {
                        Text(currentLabel)
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                            .padding(.horizontal, 28)
                        if phase != .idle {
                            Text("\(stepRemaining)s")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .tracking(1.2)
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                .padding(.vertical, 4)

                VStack(spacing: 4) {
                    Text("UP NEXT")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .tracking(2.0)
                        .foregroundColor(Theme.textTertiary)
                    Text(nextLabel)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(
                label: "Samples",
                value: sampleCount > 0 ? "\(sampleCount)" : "0",
                tint: Theme.accent
            )
            statTile(
                label: "Gesture",
                value: recording && sequenceIndex < GESTURES.count
                    ? "\(sequenceIndex + 1)/\(GESTURES.count)"
                    : "—/\(GESTURES.count)",
                tint: Theme.accent2
            )
        }
    }

    private func statTile(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .tracking(2.0)
                .foregroundColor(Theme.textTertiary)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.25), lineWidth: 1)
        )
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Text(statusLine)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            NeonButton(
                label: recording ? "Stop" : "Start",
                icon: recording ? "stop.fill" : "play.fill",
                filled: true,
                tint: recording ? Theme.danger : Theme.accent
            ) {
                if recording { stop() } else { start() }
            }

            NeonButton(
                label: "Save CSV",
                icon: "square.and.arrow.down",
                filled: false,
                tint: Theme.accent3,
                disabled: recording || memory.isEmpty
            ) {
                save()
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
        counterLabel = "—"
        statusLine = "Capture in progress — hold each pose"
        memory.removeAll()
        labels.removeAll()
        beginCountdown()
    }

    private func stop() {
        phaseTimer?.invalidate()
        phaseTimer = nil
        recording = false
        currentLabel = "—"
        nextLabel = "—"
        phase = .idle
        stepRemaining = 0
        stepTotal = 1
        if memory.isEmpty {
            statusLine = "Ready to capture"
        } else {
            statusLine = "Buffer holds \(memory.count) samples — save to export"
        }
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
        let saved = memory.count
        counterLabel = "Saved \(saved) samples to \(url.lastPathComponent)"
        statusLine = "Saved \(saved) samples → \(url.lastPathComponent)"
        memory.removeAll()
        labels.removeAll()
    }

    private func beginCountdown() {
        guard recording else { return }
        guard sequenceIndex < GESTURES.count else { stop(); return }
        phase = .countdown
        stepTotal = countdownSeconds
        stepRemaining = countdownSeconds
        currentLabel = GESTURES[sequenceIndex]
        nextLabel = "Get ready • \(stepRemaining)s"
        startTimer()
    }

    private func beginRecording() {
        phase = .recording
        stepTotal = recordSeconds
        stepRemaining = recordSeconds
        let next = sequenceIndex + 1 < GESTURES.count ? GESTURES[sequenceIndex + 1] : "Session complete"
        currentLabel = GESTURES[sequenceIndex]
        nextLabel = next
    }

    private func startTimer() {
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            Task { @MainActor in
                guard recording else { t.invalidate(); return }
                stepRemaining -= 1
                if phase == .countdown {
                    if stepRemaining > 0 {
                        nextLabel = "Get ready • \(stepRemaining)s"
                    } else {
                        beginRecording()
                    }
                } else if phase == .recording {
                    if stepRemaining > 0 {
                        // Keep gesture label visible; ring shows progress.
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
