import SwiftUI

struct ArmDialogView: View {
    @ObservedObject var state: EmbraceState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 16) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "dot.radiowaves.left.and.right", title: "Discovered", tint: Theme.accent2)

                            if state.arm.discovered.isEmpty {
                                emptyState
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(state.arm.discovered) { d in
                                        deviceRow(name: d.name, id: d.id)
                                    }
                                }
                            }
                        }
                    }

                    serviceFooter

                    Spacer(minLength: 8)

                    NeonButton(
                        label: state.arm.scanning ? "Scanning…" : "Refresh Scan",
                        icon: state.arm.scanning ? "arrow.triangle.2.circlepath" : "arrow.clockwise",
                        filled: false,
                        tint: Theme.accent,
                        disabled: state.arm.scanning
                    ) {
                        state.arm.startScan()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { state.arm.startScan() }
            .onDisappear { state.arm.stopScan() }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CONNECT")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(Theme.accentGradient)
                Text("BLUETOOTH ARMS NEARBY")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(2.2)
                    .foregroundColor(Theme.textTertiary)
            }
            Spacer()
            Button {
                state.arm.stopScan()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            ScanIndicator(active: state.arm.scanning)
            VStack(alignment: .leading, spacing: 2) {
                Text(state.arm.scanning ? "Scanning…" : "No devices found")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(state.arm.scanning ? "Listening for advertising packets" : "Pull refresh to scan again")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
            }
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
    }

    private func deviceRow(name: String, id: UUID) -> some View {
        Button {
            state.arm.connect(id)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accent2.opacity(0.15))
                        .frame(width: 38, height: 38)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.accent2.opacity(0.45), lineWidth: 1)
                        .frame(width: 38, height: 38)
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.accent2)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text(id.uuidString.lowercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var serviceFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
            Text("SERVICE \(ARM_SERVICE_UUID.uuidString.lowercased())")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(Theme.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 4)
    }
}

private struct ScanIndicator: View {
    let active: Bool
    @State private var rotate = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 2)
                .frame(width: 36, height: 36)
            if active {
                Circle()
                    .trim(from: 0, to: 0.28)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(rotate ? 360 : 0))
                    .animation(.linear(duration: 1.1).repeatForever(autoreverses: false), value: rotate)
                    .onAppear { rotate = true }
            } else {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
            }
        }
    }
}
