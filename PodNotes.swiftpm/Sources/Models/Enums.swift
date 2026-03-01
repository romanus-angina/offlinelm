import SwiftUI

// MARK: - ProcessingStatus

enum ProcessingStatus: String, Codable, CaseIterable, Sendable {
    case importing   = "importing"
    case processing  = "processing"
    case ready       = "ready"
    case failed      = "failed"

    var label: String {
        switch self {
        case .importing:  return "Importing"
        case .processing: return "Generating"
        case .ready:      return "Ready"
        case .failed:     return "Failed"
        }
    }

    var icon: String {
        switch self {
        case .importing:  return "arrow.down.to.line"
        case .processing: return "waveform"
        case .ready:      return "checkmark.circle.fill"
        case .failed:     return "exclamationmark.circle.fill"
        }
    }

    var isTerminal: Bool   { self == .ready || self == .failed }
    var isInProgress: Bool { self == .importing || self == .processing }

    @available(iOS 26, *)
    var tintColor: Color {
        switch self {
        case .importing:  return AppTheme.Colors.ana5
        case .processing: return AppTheme.Colors.ana4
        case .ready:      return AppTheme.Colors.statusReady
        case .failed:     return AppTheme.Colors.statusFailed
        }
    }
}

// MARK: - Speaker

enum Speaker: String, Codable, CaseIterable {
    case hostA = "Amani"
    case hostB = "Zuri"

    /// The name displayed in transcripts, prompts, and UI.
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .hostA: return "person.fill"
        case .hostB: return "person.crop.circle.fill"
        }
    }

    /// The accent color for this speaker in transcript and waveform views.
    var accentColor: Color {
        switch self {
        case .hostA: return AppTheme.Colors.ana1   // electric blue
        case .hostB: return AppTheme.Colors.ana5   // warm amber
        }
    }

    /// Role description used in LLM prompts and onboarding.
    var roleDescription: String {
        switch self {
        case .hostA: return "introduces and explains concepts"
        case .hostB: return "asks clarifying questions and makes analogies"
        }
    }

    /// Short label for settings UI.
    var settingsLabel: String {
        switch self {
        case .hostA: return "Amani (Host A)"
        case .hostB: return "Zuri (Host B)"
        }
    }
}
