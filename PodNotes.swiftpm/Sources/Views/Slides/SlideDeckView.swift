import SwiftUI

// MARK: - SlideDeckView

@available(iOS 26, *)
struct SlideDeckView: View {

    @State private var vm: SlideDeckViewModel
    @Environment(\.dismiss) private var dismiss

    init(module: StudyModule) {
        _vm = State(initialValue: SlideDeckViewModel(slides: module.slides))
    }

    // Preview / debug path -- no StudyModule needed.
    init(viewModel: SlideDeckViewModel) {
        _vm = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                deckHeader
                deckPager
                deckFooter
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var deckHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.backgroundSecondary)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Text(vm.positionLabel)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundPrimary)
    }

    // MARK: - Pager

    private var deckPager: some View {
        TabView(selection: $vm.currentIndex) {
            ForEach(vm.slides.indices, id: \.self) { i in
                DeckPage(slide: vm.slides[i])
                    .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(AppTheme.Motion.standard, value: vm.currentIndex)
    }

    // MARK: - Footer

    private var deckFooter: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            // Previous
            Button {
                withAnimation(AppTheme.Motion.standard) {
                    vm.goToPrevious()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        vm.isOnFirstSlide
                            ? AppTheme.Colors.textTertiary
                            : AppTheme.Colors.textPrimary
                    )
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(vm.isOnFirstSlide)

            Spacer()

            // Dot indicators
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(vm.slides.indices, id: \.self) { i in
                    Capsule()
                        .fill(
                            i == vm.currentIndex
                                ? AppTheme.Colors.ana4
                                : AppTheme.Colors.textTertiary.opacity(0.4)
                        )
                        .frame(
                            width:  i == vm.currentIndex ? 16 : 6,
                            height: 6
                        )
                        .animation(AppTheme.Motion.snappy, value: vm.currentIndex)
                }
            }

            Spacer()

            // Next
            Button {
                withAnimation(AppTheme.Motion.standard) {
                    vm.goToNext()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        vm.isOnLastSlide
                            ? AppTheme.Colors.textTertiary
                            : AppTheme.Colors.textPrimary
                    )
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(vm.isOnLastSlide)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            Rectangle()
                .fill(AppTheme.Colors.backgroundPrimary)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(AppTheme.Colors.borderSubtle),
                    alignment: .top
                )
        )
    }
}

// MARK: - DeckPage

@available(iOS 26, *)
private struct DeckPage: View {

    let slide: Slide

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                SlideCardView(slide: slide)
                    .frame(maxWidth: 600)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
            }
            .scrollIndicators(.hidden)
        }
    }
}
