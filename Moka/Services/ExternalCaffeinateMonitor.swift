import Foundation

struct ExternalProcess: Equatable {
    let pid: Int32
    let rawArgs: String
    var flags: String

    static func parseFlags(from rawArgs: String) -> String {
        // Extract flags from args like "/usr/bin/caffeinate -di" → "-di"
        let parts = rawArgs.split(separator: " ").map(String.init)
        var flags = ""
        for part in parts {
            if part.hasPrefix("-") && part != "-t" {
                flags += part.dropFirst()
            }
        }
        // Remove numeric values following -t
        var result = "-"
        let knownFlags: Set<Character> = ["d", "i", "m", "s", "u", "w", "t"]
        for ch in flags {
            if knownFlags.contains(ch) && ch != "t" {
                result.append(ch)
            }
        }
        return result == "-" ? "" : result
    }
}

@MainActor
final class ExternalCaffeinateMonitor {
    var onUpdate: ((ExternalProcess?) -> Void)?
    private var ownPID: Int32 = 0
    private var timer: Timer?

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func updateOwnPID(_ pid: Int32) {
        ownPID = pid
    }

    private func poll() {
        let ownPID = self.ownPID
        Task.detached {
            let result = await Self.findExternal(excludingPID: ownPID)
            await MainActor.run { [weak self] in
                self?.onUpdate?(result)
            }
        }
    }

    private static func findExternal(excludingPID: Int32) async -> ExternalProcess? {
        // Step 1: pgrep -x caffeinate
        guard let pgrepOutput = runCommand("/usr/bin/pgrep", args: ["-x", "caffeinate"]),
              !pgrepOutput.isEmpty else {
            return nil
        }

        let pids = pgrepOutput
            .split(separator: "\n")
            .compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
            .filter { $0 != excludingPID }

        guard let pid = pids.first else { return nil }

        // Step 2: ps -o args= -p <pid>
        guard let psOutput = runCommand("/bin/ps", args: ["-o", "args=", "-p", String(pid)]) else {
            return nil
        }
        let rawArgs = psOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        let flags = ExternalProcess.parseFlags(from: rawArgs)
        return ExternalProcess(pid: pid, rawArgs: rawArgs, flags: flags)
    }

    private static func runCommand(_ path: String, args: [String]) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        do {
            try p.run()
            p.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
