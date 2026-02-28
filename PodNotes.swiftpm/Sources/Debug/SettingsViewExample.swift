import SwiftUI

/// Example of how to integrate voice quality information into a settings view
@available(iOS 26, *)
struct SettingsViewExample: View {
    let speechService: SpeechService
    @State private var showingVoiceGuide = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VoiceInfoView(speechService: speechService)
                } header: {
                    Text("Audio Quality")
                } footer: {
                    Text("Premium voices provide more natural-sounding speech for a better learning experience.")
                }
                
                if speechService.hasBetterVoicesAvailable {
                    Section {
                        Button {
                            showingVoiceGuide = true
                        } label: {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(AppTheme.Colors.ana1)
                                Text("Learn About Voice Quality")
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
                
                Section("Other Settings") {
                    // Your other settings here
                    Text("More settings...")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Settings")
            .sheet(isPresented: $showingVoiceGuide) {
                VoiceDownloadGuideView {
                    speechService.openVoiceSettings()
                }
            }
        }
    }
}

#Preview {
    SettingsViewExample(speechService: SpeechService())
}
