import SwiftUI

// Palette source
// ana-1  rgb(0%    52.6%  42.2%)  #00866C
// ana-2  rgb(6%    27.1%   8.56%) #0F4516
// ana-3  rgb(3.56% 39.3%  22.1%)  #096438
// ana-4  rgb(35.1% 69.2%  55.3%)  #59B08D
// ana-5  rgb(47.5% 80.5%  78.2%)  #79CDC7
// ana-6  rgb(64.2% 91.9%  95%)    #A4EAF2

@available(iOS 26, *)
enum AppTheme {

    // MARK: - Colors

    enum Colors {
        // Backgrounds — neutral dark grey, no colour cast.
        static let backgroundPrimary   = Color(red: 0.06, green: 0.06, blue: 0.06)
        static let backgroundSecondary = Color(red: 0.10, green: 0.10, blue: 0.10)
        static let backgroundTertiary  = Color(red: 0.15, green: 0.15, blue: 0.15)

        // ana-1 — primary CTA, Speaker A ring, interactive chrome.
        static let ana1 = Color(red: 0.000, green: 0.526, blue: 0.422)
        // ana-2 — card bottom stop, deep surface tones.
        static let ana2 = Color(red: 0.060, green: 0.271, blue: 0.086)
        // ana-3 — card top stop, mid-depth surface.
        static let ana3 = Color(red: 0.036, green: 0.393, blue: 0.221)
        // ana-4 — secondary labels, waveform bars.
        static let ana4 = Color(red: 0.351, green: 0.692, blue: 0.553)
        // ana-5 — Speaker B, active states, status ready.
        static let ana5 = Color(red: 0.475, green: 0.805, blue: 0.782)
        // ana-6 — lightest tint, spectrum gradient tail.
        static let ana6 = Color(red: 0.642, green: 0.919, blue: 0.950)

        // Text — cool near-white that harmonises with the green-teal family.
        static let textPrimary   = Color(red: 0.90, green: 0.97, blue: 0.95)
        static let textSecondary = Color(red: 0.90, green: 0.97, blue: 0.95).opacity(0.60)
        static let textTertiary  = Color(red: 0.90, green: 0.97, blue: 0.95).opacity(0.35)

        // Status
        static let statusReady  = ana5
        static let statusFailed = Color(red: 0.96, green: 0.40, blue: 0.40)

        // Card surfaces — neutral grey lift so the ana accent colours pop against them.
        static let cardTop    = Color(red: 0.16, green: 0.16, blue: 0.16)
        static let cardBottom = Color(red: 0.10, green: 0.10, blue: 0.10)

        // Borders keyed off ana-5.
        static let borderSubtle = ana5.opacity(0.08)
        static let borderMedium = ana5.opacity(0.16)

        // Named glow tokens for button shadows.
        static let glowAna1 = ana1.opacity(0.45)
        static let glowAna5 = ana5.opacity(0.30)
    }

    // MARK: - Gradients

    enum Gradients {
        static let appBackground = LinearGradient(
            colors: [Colors.backgroundPrimary, Colors.backgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )

        static let card = LinearGradient(
            colors: [Colors.cardTop, Colors.cardBottom],
            startPoint: .top,
            endPoint: .bottom
        )

        // Primary CTA — ana-1 down to ana-3.
        static let primary = LinearGradient(
            colors: [Colors.ana1, Colors.ana3],
            startPoint: .top,
            endPoint: .bottom
        )

        // Secondary / Speaker B — ana-5 down to ana-1.
        static let secondary = LinearGradient(
            colors: [Colors.ana5, Colors.ana1],
            startPoint: .top,
            endPoint: .bottom
        )

        // Full spectrum — ana-4 through ana-5 to ana-6.
        static let spectrum = LinearGradient(
            colors: [Colors.ana4, Colors.ana5, Colors.ana6],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Layout

    enum Spacing {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat   = 8
        static let md: CGFloat   = 12
        static let lg: CGFloat   = 20
        static let xl: CGFloat   = 28
        static let pill: CGFloat = 999
    }

    // MARK: - Animation

    enum Motion {
        static let standard = Animation.spring(response: 0.38, dampingFraction: 0.80)
        static let snappy   = Animation.spring(response: 0.28, dampingFraction: 0.85)
        static let gentle   = Animation.easeInOut(duration: 0.40)
    }
}

// MARK: - View modifier

@available(iOS 26, *)
private struct CardSurfaceModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Gradients.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            )
    }
}

@available(iOS 26, *)
extension View {
    func cardSurface(cornerRadius: CGFloat = AppTheme.Radius.lg) -> some View {
        modifier(CardSurfaceModifier(cornerRadius: cornerRadius))
    }
}
