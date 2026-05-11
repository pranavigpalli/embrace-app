import SwiftUI

struct ArmDialogView: View {
    @ObservedObject var state: EmbraceState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if state.arm.discovered.isEmpty {
                        HStack {
                            if state.arm.scanning {
                                ProgressView()
                                Text("Scanning...")
                            } else {
                                Text("No devices found").foregroundColor(.secondary)
                            }
                        }
                    } else {
                        ForEach(state.arm.discovered) { d in
                            Button {
                                state.arm.connect(d.id)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(d.name)
                                        Text(d.id.uuidString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } footer: {
                    Text("Filtering on service UUID: \(ARM_SERVICE_UUID.uuidString.lowercased())")
                        .font(.caption2)
                }
            }
            .navigationTitle("Bluetooth Arms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        state.arm.stopScan()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        state.arm.startScan()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(state.arm.scanning)
                }
            }
            .onAppear { state.arm.startScan() }
        }
    }
}
