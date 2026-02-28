import SwiftUI

@available(iOS 26, *)
struct OnboardingView: View {

    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var appeared = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "doc.text.fill",
            iconGradient: [AppTheme.Colors.ana1, AppTheme.Colors.ana3],
            title: "Import Your Notes",
            subtitle: "Drop in any PDF: lecture notes, textbooks, study guides. PodNotes extracts the content automatically."
        ),
        OnboardingPage(
            icon: "waveform",
            iconGradient: [AppTheme.Colors.ana4, AppTheme.Colors.ana5],
            title: "Listen and Learn",
            subtitle: "Onboard AI transforms your notes into a two-host podcast so you can study while commuting, cooking, or doing anything else!"
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            iconGradient: [AppTheme.Colors.ana5, AppTheme.Colors.ana6],
            title: "Test Your Knowledge",
            subtitle: "Auto-generated flashcards and quizzes help you retain what matters. All processing happens on-device so you don't need to worry about internet!"
        ),
    ]

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 380)

                // Page dots
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(
                                index == currentPage
                                    ? AppTheme.Colors.ana4
                                    : AppTheme.Colors.textTertiary.opacity(0.4)
                            )
                            .frame(
                                width: index == currentPage ? 24 : 8,
                                height: 8
                            )
                            .animation(AppTheme.Motion.snappy, value: currentPage)
                    }
                }
                .padding(.top, AppTheme.Spacing.xl)

                Spacer()

                // Action buttons
                VStack(spacing: AppTheme.Spacing.md) {
                    if currentPage == pages.count - 1 {
                        getStartedButton
                    } else {
                        continueButton
                    }

                    if currentPage < pages.count - 1 {
                        Button {
                            onComplete()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: - Page view

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.iconGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.15)
                    )
                    .frame(width: 120, height: 120)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: page.iconGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.iconGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                Text(page.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
    }

    // MARK: - Buttons

    private var continueButton: some View {
        Button {
            withAnimation(AppTheme.Motion.standard) {
                currentPage += 1
            }
        } label: {
            Text("Continue")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.Gradients.primary)
                .clipShape(Capsule())
                .shadow(color: AppTheme.Colors.glowAna1, radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var getStartedButton: some View {
        Button {
            onComplete()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text("Get Started")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.Gradients.primary)
            .clipShape(Capsule())
            .shadow(color: AppTheme.Colors.glowAna1, radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data model

private struct OnboardingPage {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let subtitle: String
}
