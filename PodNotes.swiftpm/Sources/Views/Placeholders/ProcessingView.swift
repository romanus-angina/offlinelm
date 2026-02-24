import SwiftUI

@available(iOS 26, *)
struct ProcessingView: View {
    let module: StudyModule
    @Environment(AppRouter.self) private var router

    @State private var animating = false

    private let barHeights: [Double] = [0.45, 0.75, 1.0, 0.60, 0.88, 0.50, 0.70]

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()
                animatedWaveform
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text(module.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(statusDescription)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                StatusPillView(status: module.status)
                Spacer()
                Button(action: { router.goToDashboard() }) {
                    Text("Back to Library")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(AppTheme.Spacing.xl)
        }
        .navigationTitle("Processing")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear { animating = true }
    }

    private var animatedWaveform: some View {
        HStack(alignment: .center, spacing: 6) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(AppTheme.Gradients.spectrum)
                    .frame(width: 5, height: animating ? 64 * height : 12)
                    .animation(
                        .easeInOut(duration: 0.55 + Double(index) * 0.07)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: animating
                    )
            }
        }
        .frame(height: 64)
    }

    private var statusDescription: String {
        switch module.status {
        case .importing:  return "Extracting text from your PDF..."
        case .processing: return "Generating podcast script and slides.\nThis may take a moment."
        case .ready:      return "All done. Your podcast is ready to play."
        case .failed:     return "Something went wrong during generation.\nYou can try re-importing the PDF."
        }
    }
}
