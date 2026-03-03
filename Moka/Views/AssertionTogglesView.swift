import SwiftUI

struct AssertionTogglesView: View {
    @EnvironmentObject var vm: MokaViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Picker("", selection: $vm.sleepMode) {
                ForEach(SleepMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(vm.isActive)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        if vm.sleepMode == .full && vm.isOnBattery {
            return "Block all sleep · −s ignored on battery"
        }
        return vm.sleepMode.subtitle
    }
}
