import Foundation

@MainActor
final class CaffeinateService {
    private var process: Process?
    var onTermination: (() -> Void)?

    var currentPID: Int32? {
        process?.processIdentifier
    }

    func start(flags: CaffeinateFlags, duration: Duration) {
        var args = flags.arguments
        if let seconds = duration.seconds {
            args += ["-t", String(seconds)]
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice

        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                // Only fire if handler wasn't cleared by stop()
                self.onTermination?()
            }
        }

        do {
            try p.run()
            self.process = p
        } catch {
            print("CaffeinateService: failed to launch caffeinate: \(error)")
        }
    }

    func stop() {
        guard let p = process else { return }
        // Clear handler before terminating to prevent double-callback
        p.terminationHandler = nil
        p.terminate()
        p.waitUntilExit()
        process = nil
    }

    deinit {
        process?.terminate()
    }
}
