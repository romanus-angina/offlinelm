import SwiftUI

@available(iOS 26, *)
struct VoiceQualityBannerView: View {
    let voiceQuality: VoiceQuality
    let onOpenSettings: () -> Void
    
    @State private var isDismissed = false
    
    var body: some View {
        if !isDismissed && voiceQuality != .optimal {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Button {
                        isDismissed = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
                
                HStack(spacing: AppTheme.Spacing.sm) {
                    Button {
                        onOpenSettings()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gear")
                            Text("Open Settings")
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppTheme.Colors.ana1, in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button {
                        isDismissed = true
                    } label: {
                        Text("Maybe Later")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(bannerBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    private var iconName: String {
        switch voiceQuality {
        case .optimal:
            return "checkmark.seal.fill"
        case .good:
            return "info.circle.fill"
        case .suboptimal:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch voiceQuality {
        case .optimal:
            return AppTheme.Colors.statusReady
        case .good:
            return .blue
        case .suboptimal:
            return .orange
        }
    }
    
    private var title: String {
        switch voiceQuality {
        case .optimal:
            return "Optimal Voice Quality"
        case .good:
            return "Improve Voice Quality"
        case .suboptimal:
            return "Enhanced Voices Recommended"
        }
    }
    
    private var message: String {
        switch voiceQuality {
        case .optimal:
            return "You're using the best available voices!"
        case .good:
            return "Download enhanced voices for even more natural speech."
        case .suboptimal:
            return "For the best experience, download premium voices from Settings → Accessibility → Spoken Content → Voices."
        }
    }
    
    private var bannerBackground: Color {
        switch voiceQuality {
        case .optimal:
            return AppTheme.Colors.statusReady.opacity(0.1)
        case .good:
            return Color.blue.opacity(0.1)
        case .suboptimal:
            return Color.orange.opacity(0.1)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        VoiceQualityBannerView(voiceQuality: .suboptimal) {
            print("Opening settings")
        }
        
        VoiceQualityBannerView(voiceQuality: .good) {
            print("Opening settings")
        }
        
        VoiceQualityBannerView(voiceQuality: .optimal) {
            print("Opening settings")
        }
    }
    .padding()
    .background(AppTheme.Colors.backgroundPrimary)
}
