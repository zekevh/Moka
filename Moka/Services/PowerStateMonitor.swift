import Foundation
import IOKit.ps

extension Notification.Name {
    static let powerSourceDidChange = Notification.Name("MokaPowerSourceDidChange")
}

@MainActor
final class PowerStateMonitor {
    var onPowerSourceChange: ((Bool) -> Void)?
    private var runLoopSource: CFRunLoopSource?

    static func checkBattery() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return false }
        guard let type = IOPSGetProvidingPowerSourceType(info)?.takeRetainedValue() as String? else {
            return false
        }
        return type == kIOPSBatteryPowerValue
    }

    func start() {
        // Register for NotificationCenter updates posted from C callback
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePowerNotification),
            name: .powerSourceDidChange,
            object: nil
        )

        // C function pointer — cannot capture Swift. Posts to NotificationCenter instead.
        let callback: IOPowerSourceCallbackType = { _ in
            NotificationCenter.default.post(name: .powerSourceDidChange, object: nil)
        }
        let source = IOPSNotificationCreateRunLoopSource(callback, nil).takeRetainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        runLoopSource = source
    }

    func stop() {
        NotificationCenter.default.removeObserver(self, name: .powerSourceDidChange, object: nil)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = nil
        }
    }

    @objc private func handlePowerNotification() {
        let onBattery = Self.checkBattery()
        onPowerSourceChange?(onBattery)
    }
}
