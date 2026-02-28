import SwiftUI

@available(iOS 26, *)
struct VoiceDownloadGuideView: View {
    @Environment(\.dismiss) private var dismiss
    let onOpenSettings: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    headerSection
                    
                    benefitsSection
                    
                    instructionsSection
                    
                    tipsSection
                    
                    actionButton
                }
                .padding(AppTheme.Spacing.md)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Voice Quality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Spacer()
            }
            
            Text("Enhance Your Listening Experience")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Text("Download premium voices for natural-sounding speech that makes learning more enjoyable.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionTitle("Why Premium Voices?")
            
            benefitRow(
                icon: "waveform",
                title: "Natural Sound",
                description: "Premium voices sound more human-like with better prosody and intonation."
            )
            
            benefitRow(
                icon: "brain.head.profile",
                title: "Better Comprehension",
                description: "Natural speech patterns help your brain process information more effectively."
            )
            
            benefitRow(
                icon: "ear",
                title: "Less Fatigue",
                description: "High-quality voices are easier to listen to for extended periods."
            )
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.backgroundSecondary)
        )
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionTitle("How to Download Premium Voices")
            
            instructionStep(
                number: 1,
                text: "Tap the button below to open Settings"
            )
            
            instructionStep(
                number: 2,
                text: "Navigate to Accessibility → Spoken Content → Voices"
            )
            
            instructionStep(
                number: 3,
                text: "Select English (or your preferred language)"
            )
            
            instructionStep(
                number: 4,
                text: "Download voices marked as 'Enhanced' or 'Premium'"
            )
            
            instructionStep(
                number: 5,
                text: "Return to the app — the new voices will be used automatically"
            )
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.backgroundSecondary)
        )
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Pro Tips")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                tipRow("Download on Wi-Fi — premium voices can be 200-500 MB each")
                tipRow("Try multiple voices to find your favorites")
                tipRow("Siri voices (if available) often provide the best quality")
                tipRow("You can delete unused voices later to save storage")
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var actionButton: some View {
        Button {
            onOpenSettings()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "gear")
                Text("Open Settings")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Views
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.Colors.textPrimary)
    }
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.Colors.ana1)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(AppTheme.Colors.ana1)
                )
            
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    VoiceDownloadGuideView {
        print("Opening settings")
    }
}
