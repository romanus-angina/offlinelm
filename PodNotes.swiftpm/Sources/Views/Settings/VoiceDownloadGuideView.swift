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

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.ana1.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Circle()
                        .strokeBorder(AppTheme.Colors.ana5.opacity(0.3), lineWidth: 1)
                        .frame(width: 64, height: 64)
                    Image(systemName: "waveform.badge.plus")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.ana1, AppTheme.Colors.ana5],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                Spacer()
            }

            Text("Better Voices, Better Learning")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text("Downloading premium voices makes Alex and Sam sound significantly more natural, which helps you stay focused for longer.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionTitle("What changes")

            benefitRow(
                icon: "waveform",
                title: "Natural Intonation",
                description: "Premium voices handle pauses, emphasis, and sentence flow the way a real person would.",
                color: AppTheme.Colors.ana1
            )

            benefitRow(
                icon: "ear",
                title: "Comfortable for Long Sessions",
                description: "Smoother audio means it's easier for you to listen to the podcasts without losing focus.",
                color: AppTheme.Colors.ana4
            )
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                )
        )
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionTitle("How to get them")

            instructionStep(
                number: 1,
                text: "Tap the button at the bottom of this page"
            )

            instructionStep(
                number: 2,
                text: "Head to Accessibility > Spoken Content > Voices"
            )

            instructionStep(
                number: 3,
                text: "Pick English and download any voice labelled Enhanced or Premium"
            )

            instructionStep(
                number: 4,
                text: "Return to the app and select the premium voice you downloaded"
            )
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                )
        )
    }

    // MARK: - Tips

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppTheme.Colors.ana4)
                Text("Good to know")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                tipRow("Each voice is around 200-500 MB, so Wi-Fi is your friend here.")
                tipRow("Try a couple and see which one you prefer for long study sessions.")
                tipRow("You can always remove voices you don't use to free up storage.")
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.ana4.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .strokeBorder(AppTheme.Colors.ana4.opacity(0.20), lineWidth: 1)
                )
        )
    }

    // MARK: - Action

    private var actionButton: some View {
        Button {
            onOpenSettings()
            dismiss()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "gear")
                    .font(.system(size: 15, weight: .semibold))
                Text("Open Settings")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.Gradients.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
            .shadow(color: AppTheme.Colors.glowAna1, radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reusable pieces

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(AppTheme.Colors.textTertiary)
            .tracking(1.0)
    }

    private func benefitRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Text("\(number)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.backgroundPrimary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(AppTheme.Colors.ana1)
                )

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(AppTheme.Colors.ana4.opacity(0.5))
                .frame(width: 5, height: 5)
                .offset(y: 4)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    VoiceDownloadGuideView {
        print("Opening settings")
    }
    .preferredColorScheme(.dark)
}
