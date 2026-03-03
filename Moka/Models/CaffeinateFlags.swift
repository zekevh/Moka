import Foundation

// MARK: - SleepMode

enum SleepMode: CaseIterable, Equatable {
    case screen  // -d
    case system  // -di  (default)
    case full    // -dims (requires AC)

    var label: String {
        switch self {
        case .screen: return "Screen"
        case .system: return "System"
        case .full:   return "Full"
        }
    }

    var subtitle: String {
        switch self {
        case .screen: return "Keep the display on"
        case .system: return "Prevent Mac from sleeping"
        case .full:   return "Block all sleep · requires AC"
        }
    }

    var flags: CaffeinateFlags {
        switch self {
        case .screen: return CaffeinateFlags(display: true,  idle: false, disk: false, system: false)
        case .system: return CaffeinateFlags(display: true,  idle: true,  disk: false, system: false)
        case .full:   return CaffeinateFlags(display: true,  idle: true,  disk: true,  system: true)
        }
    }
}

// MARK: - Duration

enum Duration: Equatable, Hashable {
    case indefinite
    case minutes(Int)
    case custom

    var seconds: Int? {
        switch self {
        case .indefinite, .custom: return nil
        case .minutes(let m): return m * 60
        }
    }

    var label: String {
        switch self {
        case .indefinite:    return "Always"
        case .minutes(30):   return "30m"
        case .minutes(60):   return "1h"
        case .minutes(120):  return "2h"
        case .minutes(let m): return "\(m)m"
        case .custom:        return "Custom"
        }
    }
}

// MARK: - CaffeinateFlags

struct CaffeinateFlags: Equatable {
    var display: Bool = true
    var idle: Bool = true
    var disk: Bool = false
    var system: Bool = false

    var arguments: [String] {
        var args: [String] = []
        if display { args.append("-d") }
        if idle    { args.append("-i") }
        if disk    { args.append("-m") }
        if system  { args.append("-s") }
        return args
    }

    var compactFlagString: String {
        var s = "-"
        if display { s += "d" }
        if idle    { s += "i" }
        if disk    { s += "m" }
        if system  { s += "s" }
        return s == "-" ? "" : s
    }
}
