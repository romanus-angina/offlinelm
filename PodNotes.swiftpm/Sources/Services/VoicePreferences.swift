import SwiftUI
import AVFoundation

// MARK: - VoicePreferences

/// Reads/writes the user's chosen AVSpeechSynthesisVoice identifiers
/// for each podcast host. Falls back to automatic selection when no
/// preference is stored.
///
/// Usage:
///   let prefs = VoicePreferences()
///   let voice = prefs.resolvedVoice(for: .hostA)
///
@available(iOS 26, *)
@Observable
final class VoicePreferences {

    // MARK: - Persisted keys

    /// Voice identifier for host A (Amani). Empty string means "auto".
    @ObservationIgnored
    @AppStorage("voiceID_hostA") private var storedHostAID: String = ""

    /// Voice identifier for host B (Zuri). Empty string means "auto".
    @ObservationIgnored
    @AppStorage("voiceID_hostB") private var storedHostBID: String = ""

    // MARK: - Public interface

    var hostAVoiceID: String {
            get {
                access(keyPath: \.hostAVoiceID)
                return storedHostAID
            }
            set {
                withMutation(keyPath: \.hostAVoiceID) {
                    storedHostAID = newValue
                }
            }
        }

    var hostBVoiceID: String {
            get {
                access(keyPath: \.hostBVoiceID)
                return storedHostBID
            }
            set {
                withMutation(keyPath: \.hostBVoiceID) {
                    storedHostBID = newValue
                }
            }
        }

    // MARK: - Available voices

    /// All English voices on the device, sorted by quality tier then name.
    var availableEnglishVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .filter { !isNoveltyVoice($0) }
            .sorted { lhs, rhs in
                if lhs.quality.rawValue != rhs.quality.rawValue {
                    return lhs.quality.rawValue > rhs.quality.rawValue
                }
                return lhs.name < rhs.name
            }
    }

    // MARK: - Resolve voice for a speaker

    /// Returns the AVSpeechSynthesisVoice for a given speaker,
    /// honoring the user's preference if one is set and still available.
    /// Falls back to automatic selection otherwise.
    func resolvedVoice(for speaker: Speaker) -> AVSpeechSynthesisVoice? {
        let preferredID: String
        switch speaker {
        case .hostA: preferredID = hostAVoiceID
        case .hostB: preferredID = hostBVoiceID
        }

        // If the user has a preference and the voice is still installed, use it.
        if !preferredID.isEmpty,
           let voice = AVSpeechSynthesisVoice(identifier: preferredID) {
            return voice
        }

        // Otherwise fall back to auto-selection.
        return autoSelectVoice(for: speaker)
    }

    /// Human-readable name for the currently resolved voice.
    func voiceName(for speaker: Speaker) -> String {
        resolvedVoice(for: speaker)?.name ?? "Default"
    }

    /// Quality tier label for display.
    func qualityLabel(for voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .enhanced: return "Enhanced"
        case .premium:  return "Premium"
        default:        return "Standard"
        }
    }

    /// Whether the user has explicitly chosen a voice for this speaker.
    func hasCustomSelection(for speaker: Speaker) -> Bool {
        switch speaker {
        case .hostA: return !hostAVoiceID.isEmpty
        case .hostB: return !hostBVoiceID.isEmpty
        }
    }

    /// Clears the user's custom voice for a speaker, reverting to auto.
    func resetToAuto(for speaker: Speaker) {
        switch speaker {
        case .hostA: hostAVoiceID = ""
        case .hostB: hostBVoiceID = ""
        }
    }

    // MARK: - Auto selection (same logic SpeechService used before)

    private func autoSelectVoice(for speaker: Speaker) -> AVSpeechSynthesisVoice? {
        let voices = availableEnglishVoices

        // Try to find two distinct voices -- one for each host.
        // Host A gets the first best voice, Host B gets the second distinct one.
        let bestVoices = voices.prefix(10)
        let grouped = Dictionary(grouping: bestVoices) { $0.name.components(separatedBy: " ").first ?? $0.name }
        let distinctNames = grouped.keys.sorted()

        switch speaker {
        case .hostA:
            if let firstName = distinctNames.first,
               let voice = grouped[firstName]?.first {
                return voice
            }
            return voices.first
        case .hostB:
            if distinctNames.count >= 2,
               let secondName = distinctNames.dropFirst().first,
               let voice = grouped[secondName]?.first {
                return voice
            }
            // If only one distinct name exists, just use the second voice in the list.
            if voices.count >= 2 { return voices[1] }
            return voices.first
        }
    }

    private func isNoveltyVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        let noveltyNames = ["Bells", "Cellos", "Organ", "Wobble", "Zarvox",
                            "Trinoids", "Whisper", "Superstar", "Albert",
                            "Bad News", "Bahh", "Boing", "Bubbles",
                            "Good News", "Jester", "Deranged"]
        return noveltyNames.contains(where: { voice.name.contains($0) })
    }
}
