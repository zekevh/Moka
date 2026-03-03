import SwiftUI

@main
struct MokaApp: App {
    @StateObject private var viewModel = MokaViewModel()

    var body: some Scene {
        MenuBarExtra(
            content: {
                MokaPanel()
                    .environmentObject(viewModel)
            },
            label: {
                Image(systemName: viewModel.isActive
                      ? "cup.and.saucer.fill"
                      : "cup.and.saucer")
            }
        )
        .menuBarExtraStyle(.window)
    }
}
