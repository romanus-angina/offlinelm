import SwiftUI
import AVFoundation

@available(iOS 26, *)
struct AppSettingsView: View {

    @State private var voicePrefs = VoicePreferences()
    @State private var showingVoiceGuide = false
    @State private var expandedPicker: Speaker? = nil
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    voiceSection
                    aboutSection
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
                openVoiceSettings()
            }
        }
    }

    // MARK: - Voice section

    private var voiceSection: some View {
        SettingsSectionView(title: "Voices") {
            VStack(spacing: 0) {
                // Host A picker
                VoicePickerRow(
                    speaker: .hostA,
                    voicePrefs: voicePrefs,
                    isExpanded: expandedPicker == .hostA,
                    onToggle: {
                        withAnimation(AppTheme.Motion.snappy) {
                            expandedPicker = expandedPicker == .hostA ? nil : .hostA
                        }
                    }
                )

                Divider()
                    .background(AppTheme.Colors.borderSubtle)
                    .padding(.vertical, AppTheme.Spacing.sm)

                // Host B picker
                VoicePickerRow(
                    speaker: .hostB,
                    voicePrefs: voicePrefs,
                    isExpanded: expandedPicker == .hostB,
                    onToggle: {
                        withAnimation(AppTheme.Motion.snappy) {
                            expandedPicker = expandedPicker == .hostB ? nil : .hostB
                        }
                    }
                )

                // Download better voices link
                if voicePrefs.availableEnglishVoices.allSatisfy({ $0.quality == .default }) {
                    Divider()
                        .background(AppTheme.Colors.borderSubtle)
                        .padding(.vertical, AppTheme.Spacing.sm)

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

                #if DEBUG
                Divider()
                    .background(AppTheme.Colors.borderSubtle)

                let voices = AVSpeechSynthesisVoice.speechVoices()
                let english = voices.filter { $0.language.hasPrefix("en") }
                SettingsInfoRow(
                    icon: "ladybug",
                    label: "English Voices",
                    value: "\(english.count) installed"
                )
                #endif
            }
        }
    }

    // MARK: - Helpers

    private func openVoiceSettings() {
        guard let url = URL(string: "App-Prefs:root=ACCESSIBILITY&path=SPEECH") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let fallback = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(fallback)
        }
    }
}

// MARK: - VoicePickerRow

@available(iOS 26, *)
private struct VoicePickerRow: View {

    let speaker: Speaker
    let voicePrefs: VoicePreferences
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Summary row (always visible)
            Button(action: onToggle) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Circle()
                        .fill(speaker.accentColor)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(speaker.settingsLabel)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                        Text(speaker.roleDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }

                    Spacer()

                    Text(voicePrefs.voiceName(for: speaker))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
            .buttonStyle(.plain)

            // Expanded voice list
            if isExpanded {
                voiceList
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var voiceList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Auto option
            VoiceOptionRow(
                name: "Automatic",
                qualityLabel: nil,
                isSelected: !voicePrefs.hasCustomSelection(for: speaker),
                accentColor: speaker.accentColor
            ) {
                withAnimation(AppTheme.Motion.snappy) {
                    voicePrefs.resetToAuto(for: speaker)
                }
            }

            // Available voices
            ForEach(voicePrefs.availableEnglishVoices, id: \.identifier) { voice in
                let isSelected = selectedVoiceID == voice.identifier

                VoiceOptionRow(
                    name: voice.name,
                    qualityLabel: voicePrefs.qualityLabel(for: voice),
                    isSelected: isSelected,
                    accentColor: speaker.accentColor
                ) {
                    withAnimation(AppTheme.Motion.snappy) {
                        switch speaker {
                        case .hostA: voicePrefs.hostAVoiceID = voice.identifier
                        case .hostB: voicePrefs.hostBVoiceID = voice.identifier
                        }
                    }
                }
            }
        }
        .padding(.top, AppTheme.Spacing.sm)
        .padding(.leading, AppTheme.Spacing.lg)
    }

    private var selectedVoiceID: String {
        switch speaker {
        case .hostA: return voicePrefs.hostAVoiceID
        case .hostB: return voicePrefs.hostBVoiceID
        }
    }
}

// MARK: - VoiceOptionRow

@available(iOS 26, *)
private struct VoiceOptionRow: View {
    let name: String
    let qualityLabel: String?
    let isSelected: Bool
    let accentColor: Color
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        isSelected ? accentColor : AppTheme.Colors.textTertiary.opacity(0.5)
                    )

                Text(name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(
                        isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary
                    )

                if let quality = qualityLabel, quality != "Standard" {
                    Text(quality)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.12))
                        )
                }

                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
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
