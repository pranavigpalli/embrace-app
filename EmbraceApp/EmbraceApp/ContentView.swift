import SwiftUI

struct ContentView: View {
    @StateObject private var state = EmbraceState()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    deviceCard(
                        title: "MindRove",
                        status: state.mindroveStatus,
                        primaryLabel: state.mindroveStatus.isConnected ? "Disconnect" : "Connect",
                        primaryAction: toggleMindRove,
                        secondary: AnyView(
                            Button {
                                state.showRecordSheet = true
                            } label: {
                                Label("Record", systemImage: "record.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(!state.mindroveStatus.isConnected)
                        )
                    )

                    deviceCard(
                        title: "Arm",
                        status: state.armStatus,
                        primaryLabel: state.armStatus.isConnected ? "Disconnect" : "Connect",
                        primaryAction: toggleArm,
                        secondary: nil
                    )

                    modelCard

                    signalsCard

                    predictionsCard
                }
                .padding(16)
            }
            .navigationTitle("Embrace")
            .sheet(isPresented: $state.showRecordSheet) {
                RecordView(state: state)
            }
            .sheet(isPresented: $state.showArmDialog) {
                ArmDialogView(state: state)
            }
        }
    }

    private func deviceCard(title: String, status: ConnectStatus, primaryLabel: String, primaryAction: @escaping () -> Void, secondary: AnyView?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(status.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(status.color)
            }
            Button(action: primaryAction) {
                Text(primaryLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            if let secondary { secondary }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var modelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Model").font(.headline)
            HStack {
                Text("Model:")
                Spacer()
                Text(state.modelName).foregroundColor(.secondary)
            }
            HStack {
                Text("Core ML:")
                Spacer()
                Text(state.modelLoaded ? "loaded" : "not loaded")
                    .fontWeight(.bold)
                    .foregroundColor(state.modelLoaded ? .green : .red)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var signalsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Signals").font(.headline).padding(.bottom, 4)
            ForEach(0..<8, id: \.self) { i in
                SignalBar(
                    label: "Channel \(i + 1)",
                    rawValue: state.signalValues[i],
                    enabled: state.signalsEnabled
                )
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var predictionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Predictions").font(.headline)
            let cols = [GridItem(.adaptive(minimum: 90), spacing: 8)]
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(0..<GESTURES.count, id: \.self) { i in
                    GestureBox(label: GESTURES[i], status: state.predictionStates[i])
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func toggleMindRove() {
        if state.mindroveStatus.isConnected {
            state.mindrove.stop()
        } else {
            state.mindrove.start()
        }
    }

    private func toggleArm() {
        if state.armStatus.isConnected {
            state.arm.disconnect()
        } else {
            state.showArmDialog = true
        }
    }
}

struct SignalBar: View {
    let label: String
    let rawValue: Double
    let enabled: Bool

    private var fraction: Double {
        if !enabled { return 0 }
        let clamped = min(MAX_SIG, max(MIN_SIG, rawValue))
        return (clamped - MIN_SIG) / (MAX_SIG - MIN_SIG)
    }

    private var displayText: String {
        enabled ? "\(label): \(Int(rawValue))" : label
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.tertiarySystemBackground))
                RoundedRectangle(cornerRadius: 4)
                    .fill(enabled ? Color.accentColor : Color.gray.opacity(0.35))
                    .frame(width: max(0, geo.size.width * fraction))
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                Text(displayText)
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.primary)
            }
        }
        .frame(height: 22)
    }
}

struct GestureBox: View {
    let label: String
    let status: PredictionStatus

    private var fill: Color {
        switch status {
        case .inactive: return Color(.tertiarySystemBackground)
        case .dim: return Color(.secondarySystemBackground)
        case .lit: return Color.green
        }
    }

    private var textColor: Color {
        status == .lit ? .white : .primary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(fill)
            RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1)
            Text(label).font(.callout).fontWeight(.medium).foregroundColor(textColor)
        }
        .frame(height: 70)
    }
}

#Preview {
    ContentView()
}
