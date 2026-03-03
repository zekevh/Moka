import Foundation
import Combine
import ServiceManagement

@MainActor
final class MokaViewModel: ObservableObject {

    // MARK: - State

    enum AppState: Equatable {
        case inactive
        case mokaManaged
        case terminalProcess(ExternalProcess)
    }

    @Published var appState: AppState = .inactive
    @Published var sleepMode: SleepMode = .system
    @Published var duration: Duration = .indefinite
    @Published var customMinutes: Int = 30
    @Published var isOnBattery: Bool = false
    @Published var isLaunchAtLoginEnabled: Bool = false
    @Published var timeRemaining: TimeInterval? = nil

    // MARK: - Derived

    var isActive: Bool { appState != .inactive }

    var isTerminalProcess: Bool {
        if case .terminalProcess = appState { return true }
        return false
    }

    var terminalFlags: String? {
        if case .terminalProcess(let ext) = appState { return ext.flags }
        return nil
    }

    enum StatusDot { case inactive, active }

    var statusDotColor: StatusDot {
        appState == .inactive ? .inactive : .active
    }

    var statusText: String {
        switch appState {
        case .inactive:
            return "Mac can sleep normally"
        case .mokaManaged:
            if let remaining = timeRemaining {
                let mins = Int(remaining) / 60
                let secs = Int(remaining) % 60
                return String(format: "Keeping awake · %d:%02d left", mins, secs)
            }
            return "Keeping awake"
        case .terminalProcess(let ext):
            return "Keeping awake · terminal \(ext.flags)"
        }
    }

    // MARK: - Services

    private let caffeinateService = CaffeinateService()
    private let externalMonitor = ExternalCaffeinateMonitor()
    private let powerMonitor = PowerStateMonitor()

    // MARK: - Timer

    private var countdownTimer: Timer?
    private var endDate: Date?

    // MARK: - Init

    init() {
        isOnBattery = PowerStateMonitor.checkBattery()
        isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled

        caffeinateService.onTermination = { [weak self] in
            self?.handleCaffeinateTermination()
        }

        externalMonitor.onUpdate = { [weak self] ext in
            self?.handleExternalUpdate(ext)
        }

        powerMonitor.onPowerSourceChange = { [weak self] onBattery in
            self?.handlePowerChange(onBattery)
        }

        externalMonitor.start()
        powerMonitor.start()
    }

    // MARK: - Actions

    func startKeepAwake() {
        let resolvedDuration: Duration
        switch duration {
        case .custom:
            resolvedDuration = .minutes(customMinutes)
        default:
            resolvedDuration = duration
        }

        var resolvedFlags = sleepMode.flags
        if isOnBattery { resolvedFlags.system = false }

        caffeinateService.start(flags: resolvedFlags, duration: resolvedDuration)

        if let pid = caffeinateService.currentPID {
            externalMonitor.updateOwnPID(pid)
        }

        appState = .mokaManaged

        if let seconds = resolvedDuration.seconds {
            endDate = Date().addingTimeInterval(TimeInterval(seconds))
            timeRemaining = TimeInterval(seconds)
            startCountdownTimer()
        } else {
            endDate = nil
            timeRemaining = nil
        }
    }

    func stopKeepAwake() {
        switch appState {
        case .mokaManaged:
            caffeinateService.stop()
            externalMonitor.updateOwnPID(0)
            stopCountdownTimer()
        case .terminalProcess(let ext):
            kill(ext.pid, SIGTERM)
        case .inactive:
            break
        }
        appState = .inactive
    }

    func toggleLaunchAtLogin() {
        do {
            if isLaunchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
                isLaunchAtLoginEnabled = false
            } else {
                try SMAppService.mainApp.register()
                isLaunchAtLoginEnabled = true
            }
        } catch {
            print("MokaViewModel: SMAppService error: \(error)")
        }
    }

    // MARK: - Countdown Timer

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickCountdown()
            }
        }
    }

    private func tickCountdown() {
        guard let end = endDate else { return }
        let remaining = end.timeIntervalSinceNow
        if remaining <= 0 {
            stopCountdownTimer()
            timeRemaining = nil
        } else {
            timeRemaining = remaining
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        endDate = nil
        timeRemaining = nil
    }

    // MARK: - Handlers

    private func handleCaffeinateTermination() {
        guard case .mokaManaged = appState else { return }
        stopCountdownTimer()
        appState = .inactive
    }

    private func handleExternalUpdate(_ ext: ExternalProcess?) {
        if case .mokaManaged = appState { return }
        if let ext {
            appState = .terminalProcess(ext)
        } else if case .terminalProcess = appState {
            appState = .inactive
        }
    }

    private func handlePowerChange(_ onBattery: Bool) {
        isOnBattery = onBattery
        // If running Full mode (includes -s) and switched to battery, restart without -s
        if onBattery, sleepMode == .full, case .mokaManaged = appState {
            caffeinateService.stop()
            startKeepAwake()
        }
    }
}
