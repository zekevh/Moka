import SwiftUI

struct DurationPickerView: View {
    @EnvironmentObject var vm: MokaViewModel

    private let presets: [Duration] = [.indefinite, .minutes(30), .minutes(60), .minutes(120), .custom]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(presets, id: \.self) { preset in
                    pillButton(preset)
                }
            }

            if vm.duration == .custom {
                HStack {
                    Text("Minutes:")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    TextField("", value: $vm.customMinutes, format: .number)
                        .textFieldStyle(.squareBorder)
                        .frame(width: 52)
                    Stepper("", value: $vm.customMinutes, in: 1...1440, step: 5)
                        .labelsHidden()
                }
            }
        }
        .disabled(vm.isActive)
    }

    @ViewBuilder
    private func pillButton(_ preset: Duration) -> some View {
        let isSelected = vm.duration == preset
        Button(preset.label) {
            vm.duration = preset
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .fixedSize()
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        .background(
            isSelected
                ? Color.accentColor.opacity(0.12)
                : Color.clear
        )
        .overlay(
            Capsule().strokeBorder(
                isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
                lineWidth: 1
            )
        )
        .clipShape(Capsule())
    }
}
