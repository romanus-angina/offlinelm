import SwiftUI

@available(iOS 26, *)
struct VoiceInfoView: View {
    let speechService: SpeechService
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            qualitySection
            
            Divider()
                .background(AppTheme.Colors.borderSubtle)
            
            voicesSection
            
            if speechService.hasBetterVoicesAvailable {
                Divider()
                    .background(AppTheme.Colors.borderSubtle)
                
                recommendationSection
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.backgroundSecondary)
        )
    }
    
    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Voice Quality")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .textCase(.uppercase)
            
            HStack(spacing: AppTheme.Spacing.sm) {
                qualityIndicator
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(qualityTitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Text(speechService.voiceQuality.recommendation)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private var qualityIndicator: some View {
        ZStack {
            Circle()
                .fill(indicatorColor.opacity(0.2))
                .frame(width: 44, height: 44)
            
            Image(systemName: indicatorIcon)
                .font(.system(size: 20))
                .foregroundStyle(indicatorColor)
        }
    }
    
    private var voicesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Active Voices")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .textCase(.uppercase)
            
            voiceRow(speaker: "Alex", voiceName: speechService.voiceInfo.hostA, color: Speaker.hostA.accentColor)
            voiceRow(speaker: "Sam", voiceName: speechService.voiceInfo.hostB, color: Speaker.hostB.accentColor)
        }
    }
    
    private func voiceRow(speaker: String, voiceName: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(speaker)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            Text(voiceName)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.vertical, 4)
    }
    
    private var recommendationSection: some View {
        Button {
            speechService.openVoiceSettings()
        } label: {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                Text("Download Better Voices")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(AppTheme.Colors.ana1)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Computed Properties
    
    private var qualityTitle: String {
        switch speechService.voiceQuality {
        case .optimal:
            return "Optimal"
        case .good:
            return "Good"
        case .suboptimal:
            return "Basic"
        }
    }
    
    private var indicatorIcon: String {
        switch speechService.voiceQuality {
        case .optimal:
            return "checkmark.seal.fill"
        case .good:
            return "checkmark.circle.fill"
        case .suboptimal:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var indicatorColor: Color {
        switch speechService.voiceQuality {
        case .optimal:
            return .green
        case .good:
            return .blue
        case .suboptimal:
            return .orange
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        VoiceInfoView(speechService: SpeechService())
    }
    .padding()
    .background(AppTheme.Colors.backgroundPrimary)
}
