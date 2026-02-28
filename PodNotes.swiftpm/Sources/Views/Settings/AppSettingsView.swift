import SwiftUI
import AVFoundation

@available(iOS 26, *)
struct AppSettingsView: View {

    @State private var speechService = SpeechService()
    @State private var showingVoiceGuide = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    voiceSection
                    playbackSection
                    aboutSection

                    #if DEBUG
                    debugSection
                    #endif
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingVoiceGuide) {
            VoiceDownloadGuideView {
                speechService.openVoiceSettings()
            }
        }
    }

    // MARK: - Voice section

    private var voiceSection: some View {
        SettingsSectionView(title: "Voices") {
            VStack(spacing: AppTheme.Spacing.md) {
                // Quality indicator
                HStack(spacing: AppTheme.Spacing.md) {
                    qualityBadge
                    VStack(alignment: .leading, spacing: 4) {
                        Text(qualityTitle)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Text(speechService.voiceQuality.recommendation)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Divider()
                    .background(AppTheme.Colors.borderSubtle)

                // Current voices
                VoiceRow(
                    speakerName: "Alex",
                    voiceName: speechService.voiceInfo.hostA,
                    color: Speaker.hostA.accentColor
                )
                VoiceRow(
                    speakerName: "Sam",
                    voiceName: speechService.voiceInfo.hostB,
                    color: Speaker.hostB.accentColor
                )

                if speechService.hasBetterVoicesAvailable {
                    Divider()
                        .background(AppTheme.Colors.borderSubtle)

                    Button {
                        showingVoiceGuide = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 16))
                            Text("Download Better Voices")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.Colors.ana1)
                        .padding(.vertical, AppTheme.Spacing.xs)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Playback section

    private var playbackSection: some View {
        SettingsSectionView(title: "Playback") {
            VStack(spacing: AppTheme.Spacing.md) {
                SettingsInfoRow(
                    icon: "speaker.wave.2",
                    label: "Audio Output",
                    value: "System Default"
                )

                Divider()
                    .background(AppTheme.Colors.borderSubtle)

                SettingsInfoRow(
                    icon: "waveform",
                    label: "Speech Rate",
                    value: "Natural"
                )
            }
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        SettingsSectionView(title: "About") {
            VStack(spacing: AppTheme.Spacing.md) {
                SettingsInfoRow(
                    icon: "info.circle",
                    label: "Version",
                    value: "1.0"
                )

                Divider()
                    .background(AppTheme.Colors.borderSubtle)

                SettingsInfoRow(
                    icon: "cpu",
                    label: "Processing",
                    value: "On-Device AI"
                )

                Divider()
                    .background(AppTheme.Colors.borderSubtle)

                SettingsInfoRow(
                    icon: "lock.shield",
                    label: "Privacy",
                    value: "All data stays on device"
                )

                Divider()
                    .background(AppTheme.Colors.borderSubtle)

                Button {
                    withAnimation(AppTheme.Motion.standard) {
                        hasCompletedOnboarding = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("Replay Onboarding")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Spacer()
                    }
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Debug section

    #if DEBUG
    private var debugSection: some View {
        SettingsSectionView(title: "Debug") {
            VStack(spacing: AppTheme.Spacing.md) {
                SettingsInfoRow(
                    icon: "ladybug",
                    label: "Build",
                    value: "DEBUG"
                )

                Divider()
                    .background(AppTheme.Colors.borderSubtle)

                let voices = AVSpeechSynthesisVoice.speechVoices()
                let english = voices.filter { $0.language.hasPrefix("en") }
                SettingsInfoRow(
                    icon: "person.wave.2",
                    label: "English Voices",
                    value: "\(english.count) available"
                )
            }
        }
    }
    #endif

    // MARK: - Helpers

    private var qualityBadge: some View {
        ZStack {
            Circle()
                .fill(qualityColor.opacity(0.2))
                .frame(width: 44, height: 44)
            Image(systemName: qualityIcon)
                .font(.system(size: 20))
                .foregroundStyle(qualityColor)
        }
    }

    private var qualityTitle: String {
        switch speechService.voiceQuality {
        case .optimal:    return "Optimal Quality"
        case .good:       return "Good Quality"
        case .suboptimal: return "Basic Quality"
        }
    }

    private var qualityIcon: String {
        switch speechService.voiceQuality {
        case .optimal:    return "checkmark.seal.fill"
        case .good:       return "checkmark.circle.fill"
        case .suboptimal: return "exclamationmark.circle.fill"
        }
    }

    private var qualityColor: Color {
        switch speechService.voiceQuality {
        case .optimal:    return .green
        case .good:       return .blue
        case .suboptimal: return .orange
        }
    }
}

// MARK: - SettingsSectionView

@available(iOS 26, *)
private struct SettingsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .tracking(1.0)
                .padding(.horizontal, AppTheme.Spacing.xs)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - VoiceRow

@available(iOS 26, *)
private struct VoiceRow: View {
    let speakerName: String
    let voiceName: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(speakerName)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Text(voiceName)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - SettingsInfoRow

@available(iOS 26, *)
private struct SettingsInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.ana4)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}
