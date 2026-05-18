import SwiftUI

// MARK: - Design system

enum Theme {
    static let bg0  = Color(red: 0.025, green: 0.030, blue: 0.060)
    static let bg1  = Color(red: 0.045, green: 0.055, blue: 0.100)
    static let bg2  = Color(red: 0.070, green: 0.085, blue: 0.150)

    static let cardFill   = Color.white.opacity(0.045)
    static let cardStroke = Color.white.opacity(0.10)

    static let accent  = Color(red: 0.30, green: 0.95, blue: 1.00) // cyan
    static let accent2 = Color(red: 0.60, green: 0.45, blue: 1.00) // violet
    static let accent3 = Color(red: 1.00, green: 0.35, blue: 0.75) // pink

    static let success = Color(red: 0.30, green: 0.98, blue: 0.65)
    static let warning = Color(red: 1.00, green: 0.78, blue: 0.30)
    static let danger  = Color(red: 1.00, green: 0.40, blue: 0.50)

    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary  = Color.white.opacity(0.40)

    static let accentGradient = LinearGradient(
        colors: [accent, accent2],
        startPoint: .leading, endPoint: .trailing
    )

    static let signalGradient = LinearGradient(
        colors: [accent.opacity(0.95), accent2.opacity(0.95), accent3.opacity(0.95)],
        startPoint: .leading, endPoint: .trailing
    )
}

extension ConnectStatus {
    var themeColor: Color {
        switch self {
        case .connected:    return Theme.success
        case .connecting:   return Theme.warning
        case .disconnected: return Theme.textTertiary
        case .error:        return Theme.danger
        }
    }
    var shortLabel: String {
        switch self {
        case .connected:    return "ONLINE"
        case .connecting:   return "LINKING"
        case .disconnected: return "OFFLINE"
        case .error:        return "ERROR"
        }
    }
}

// MARK: - Background

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.bg0, Theme.bg1, Theme.bg0],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.accent.opacity(0.18), .clear],
                center: .topLeading, startRadius: 10, endRadius: 360
            )
            .ignoresSafeArea()
            .blendMode(.screen)

            RadialGradient(
                colors: [Theme.accent2.opacity(0.18), .clear],
                center: .bottomTrailing, startRadius: 10, endRadius: 380
            )
            .ignoresSafeArea()
            .blendMode(.screen)
        }
    }
}

// MARK: - Card

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Header

struct CardHeader: View {
    let icon: String
    let title: String
    let tint: Color
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 34, height: 34)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 1)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tint)
            }
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(2.0)
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Status pill

struct StatusPill: View {
    let status: ConnectStatus
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(status.themeColor, lineWidth: 1.2)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulse ? 2.4 : 1.0)
                    .opacity(pulse ? 0 : 0.7)
                Circle()
                    .fill(status.themeColor)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 10, height: 10)
            Text(status.shortLabel)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(1.4)
                .foregroundColor(status.themeColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(status.themeColor.opacity(0.12))
        )
        .overlay(
            Capsule().strokeBorder(status.themeColor.opacity(0.40), lineWidth: 1)
        )
        .onAppear {
            guard status.isConnected || isConnecting else { return }
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }

    private var isConnecting: Bool {
        if case .connecting = status { return true }
        return false
    }
}

// MARK: - Buttons

struct NeonButton: View {
    let label: String
    let icon: String?
    var filled: Bool = true
    var tint: Color = Theme.accent
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(label.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(1.8)
            }
            .foregroundColor(filled ? Color.black : tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(
                        filled ? Color.white.opacity(0.30) : tint.opacity(0.55),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .opacity(disabled ? 0.35 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    @ViewBuilder private var background: some View {
        if filled {
            LinearGradient(
                colors: [tint, tint.opacity(0.65), Theme.accent2.opacity(0.85)],
                startPoint: .leading, endPoint: .trailing
            )
        } else {
            tint.opacity(0.12)
        }
    }
}

// MARK: - Brand header

struct BrandHeader: View {
    let mindrove: ConnectStatus
    let arm: ConnectStatus
    let modelLoaded: Bool

    private var allReady: Bool {
        mindrove.isConnected && arm.isConnected && modelLoaded
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(Theme.accentGradient, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.accentGradient)
                }
                Text("EMBRACE")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(8)
                    .foregroundStyle(Theme.accentGradient)
                Spacer()
            }
            HStack(spacing: 10) {
                Text("NEURAL GESTURE INTERFACE")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2.5)
                    .foregroundColor(Theme.textTertiary)
                Circle()
                    .fill(allReady ? Theme.success : Theme.textTertiary)
                    .frame(width: 5, height: 5)
                Text(allReady ? "SYSTEM READY" : "STANDBY")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2.0)
                    .foregroundColor(allReady ? Theme.success : Theme.textTertiary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var state = EmbraceState()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        BrandHeader(
                            mindrove: state.mindroveStatus,
                            arm: state.armStatus,
                            modelLoaded: state.modelLoaded
                        )
                        .padding(.bottom, 4)

                        deviceCard(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "MindRove",
                            subtitle: "EMG SENSOR",
                            tint: Theme.accent,
                            status: state.mindroveStatus,
                            primaryLabel: state.mindroveStatus.isConnected ? "Disconnect" : "Connect",
                            primaryIcon: state.mindroveStatus.isConnected ? "xmark.circle" : "bolt.horizontal.fill",
                            primaryAction: toggleMindRove,
                            secondary: AnyView(
                                NeonButton(
                                    label: "Record Session",
                                    icon: "record.circle",
                                    filled: false,
                                    tint: Theme.accent3,
                                    disabled: !state.mindroveStatus.isConnected
                                ) {
                                    state.showRecordSheet = true
                                }
                            )
                        )

                        deviceCard(
                            icon: "hand.raised.fill",
                            title: "Arm",
                            subtitle: "BLE EFFECTOR",
                            tint: Theme.accent2,
                            status: state.armStatus,
                            primaryLabel: state.armStatus.isConnected ? "Disconnect" : "Connect",
                            primaryIcon: state.armStatus.isConnected ? "xmark.circle" : "dot.radiowaves.right",
                            primaryAction: toggleArm,
                            secondary: nil
                        )

                        modelCard
                        signalsCard
                        predictionsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $state.showRecordSheet) {
                RecordView(state: state)
            }
            .sheet(isPresented: $state.showArmDialog) {
                ArmDialogView(state: state)
            }
        }
    }

    private func deviceCard(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        status: ConnectStatus,
        primaryLabel: String,
        primaryIcon: String,
        primaryAction: @escaping () -> Void,
        secondary: AnyView?
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tint.opacity(0.16))
                            .frame(width: 42, height: 42)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(tint.opacity(0.40), lineWidth: 1)
                            .frame(width: 42, height: 42)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(tint)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text(subtitle)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .tracking(1.8)
                            .foregroundColor(Theme.textTertiary)
                    }
                    Spacer()
                    StatusPill(status: status)
                }

                NeonButton(
                    label: primaryLabel,
                    icon: primaryIcon,
                    filled: !status.isConnected,
                    tint: status.isConnected ? Theme.danger : tint,
                    action: primaryAction
                )

                if let secondary { secondary }
            }
        }
    }

    private var modelCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                CardHeader(icon: "cpu", title: "Neural Model", tint: Theme.accent3)

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                state.modelLoaded ? Theme.success.opacity(0.6) : Theme.textTertiary.opacity(0.4),
                                lineWidth: 1.5
                            )
                            .frame(width: 56, height: 56)
                        Circle()
                            .fill(state.modelLoaded ? Theme.success.opacity(0.12) : Color.white.opacity(0.03))
                            .frame(width: 52, height: 52)
                        Image(systemName: state.modelLoaded ? "brain.head.profile.fill" : "brain.head.profile")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(state.modelLoaded ? Theme.success : Theme.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.modelName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(state.modelLoaded ? Theme.success : Theme.danger)
                                .frame(width: 6, height: 6)
                            Text(state.modelLoaded ? "CORE ML LOADED" : "MODEL UNAVAILABLE")
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .tracking(1.6)
                                .foregroundColor(state.modelLoaded ? Theme.success : Theme.danger)
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    private var signalsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    CardHeader(icon: "waveform", title: "Signals", tint: Theme.accent)
                    Text(state.signalsEnabled ? "LIVE" : "IDLE")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(1.6)
                        .foregroundColor(state.signalsEnabled ? Theme.success : Theme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill((state.signalsEnabled ? Theme.success : Theme.textTertiary).opacity(0.12))
                        )
                        .overlay(
                            Capsule().strokeBorder((state.signalsEnabled ? Theme.success : Theme.textTertiary).opacity(0.35), lineWidth: 1)
                        )
                }

                VStack(spacing: 8) {
                    ForEach(0..<8, id: \.self) { i in
                        SignalBar(
                            label: "CH \(i + 1)",
                            rawValue: state.signalValues[i],
                            enabled: state.signalsEnabled
                        )
                    }
                }
            }
        }
    }

    private var predictionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                CardHeader(icon: "scope", title: "Predictions", tint: Theme.accent2)
                let cols = [GridItem(.adaptive(minimum: 96), spacing: 10)]
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(0..<GESTURES.count, id: \.self) { i in
                        GestureBox(label: GESTURES[i], status: state.predictionStates[i])
                    }
                }
            }
        }
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

// MARK: - Signal bar

struct SignalBar: View {
    let label: String
    let rawValue: Double
    let enabled: Bool

    private var fraction: Double {
        if !enabled { return 0 }
        let clamped = min(MAX_SIG, max(MIN_SIG, rawValue))
        return (clamped - MIN_SIG) / (MAX_SIG - MIN_SIG)
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(1.4)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 36, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(enabled ? AnyShapeStyle(Theme.signalGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
                        .frame(width: max(0, geo.size.width * fraction))
                        .animation(.easeOut(duration: 0.12), value: fraction)
                }
            }
            .frame(height: 18)

            Text(enabled ? "\(Int(rawValue))" : "—")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(enabled ? Theme.textSecondary : Theme.textTertiary)
                .frame(width: 56, alignment: .trailing)
        }
        .frame(height: 22)
    }
}

// MARK: - Gesture box

struct GestureBox: View {
    let label: String
    let status: PredictionStatus

    private var fillStyle: AnyShapeStyle {
        switch status {
        case .lit:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Theme.success.opacity(0.55), Theme.accent.opacity(0.45)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
        case .dim:
            return AnyShapeStyle(Color.white.opacity(0.05))
        case .inactive:
            return AnyShapeStyle(Color.white.opacity(0.02))
        }
    }

    private var strokeColor: Color {
        switch status {
        case .lit:      return Theme.success
        case .dim:      return Color.white.opacity(0.12)
        case .inactive: return Color.white.opacity(0.05)
        }
    }

    private var textColor: Color {
        switch status {
        case .lit:      return .white
        case .dim:      return Theme.textSecondary
        case .inactive: return Theme.textTertiary
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fillStyle)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(strokeColor, lineWidth: status == .lit ? 1.4 : 1)

            VStack(spacing: 6) {
                Circle()
                    .fill(status == .lit ? Theme.success : Theme.textTertiary.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .shadow(color: status == .lit ? Theme.success : .clear, radius: 6)
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(textColor)
            }
        }
        .frame(height: 76)
        .shadow(
            color: status == .lit ? Theme.success.opacity(0.45) : .clear,
            radius: status == .lit ? 14 : 0
        )
        .animation(.easeOut(duration: 0.15), value: status)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
