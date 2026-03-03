import SwiftUI

struct StatusLineView: View {
    @EnvironmentObject var vm: MokaViewModel

    private var dotColor: Color {
        switch vm.statusDotColor {
        case .inactive: return Color(.labelColor).opacity(0.25)
        case .active:   return .green
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .animation(.easeInOut(duration: 0.3), value: vm.statusDotColor)
            Text(vm.statusText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
