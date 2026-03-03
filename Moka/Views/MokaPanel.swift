import SwiftUI

struct MokaPanel: View {
    @EnvironmentObject var vm: MokaViewModel

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {

                // Status line
                StatusLineView()
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                // Assertion toggles
                AssertionTogglesView()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                // Duration picker — hidden when a terminal process is in control
                if !vm.isTerminalProcess {
                    DurationPickerView()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                } else {
                    Spacer().frame(height: 4)
                }

                // Primary action — full width
                Button(vm.isActive ? "Stop" : "Keep Awake") {
                    if vm.isActive {
                        vm.stopKeepAwake()
                    } else {
                        vm.startKeepAwake()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.isActive ? .red : .accentColor)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)

                Divider()

                // Footer
                HStack {
                    Toggle("Launch at Login", isOn: Binding(
                        get: { vm.isLaunchAtLoginEnabled },
                        set: { _ in vm.toggleLaunchAtLogin() }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
            }
            .frame(maxWidth: .infinity)

            // Hidden Cmd+Q shortcut
            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
                .hidden()
        }
        .frame(width: 280)
    }
}
