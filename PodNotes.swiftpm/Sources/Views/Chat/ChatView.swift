// ChatView.swift

import SwiftUI

@available(iOS 26, *)
struct ChatView: View {

    @State private var viewModel: ChatViewModel
    @State private var inputText = ""
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init (production)

    init(module: StudyModule) {
        _viewModel = State(initialValue: ChatViewModel(module: module))
    }

    // MARK: - Init (preview)

    init(viewModel: ChatViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

                if viewModel.modelUnavailable {
                    modelUnavailableContent
                } else {
                    chatContent
                }
            }
            .navigationTitle("Ask")
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
        .preferredColorScheme(.dark)
    }

    // MARK: - Model unavailable

    private var modelUnavailableContent: some View {
        ContentUnavailableView(
            "Apple Intelligence Required",
            systemImage: "cpu",
            description: Text("This feature requires Apple Intelligence to be enabled on your device. Check Settings to enable it.")
        )
    }

    // MARK: - Chat content

    private var chatContent: some View {
        VStack(spacing: 0) {
            if viewModel.messages.isEmpty {
                emptyState
            } else {
                messageList
            }

            if let followUp = viewModel.suggestedFollowUp,
               !viewModel.isGenerating {
                followUpChip(followUp)
            }

            inputBar
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer()

            Text("Ask anything about your notes")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.Colors.textTertiary)

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(viewModel.starterQuestions, id: \.self) { question in
                    Button {
                        Task { await viewModel.send(question) }
                    } label: {
                        Text(question)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.backgroundTertiary)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }

                    if viewModel.isGenerating {
                        typingIndicator
                            .id("typing-indicator")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)
                .animation(AppTheme.Motion.standard, value: viewModel.isGenerating)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isGenerating) { _, generating in
                if generating {
                    scrollToBottom(proxy: proxy, anchor: .bottom)
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom) {
        if viewModel.isGenerating {
            withAnimation(AppTheme.Motion.gentle) {
                proxy.scrollTo("typing-indicator", anchor: anchor)
            }
        } else if let lastMessage = viewModel.messages.last {
            withAnimation(AppTheme.Motion.gentle) {
                proxy.scrollTo(lastMessage.id, anchor: anchor)
            }
        }
    }

    // MARK: - Typing indicator

    private var typingIndicator: some View {
        HStack {
            TypingDotsView()
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(AppTheme.Colors.backgroundSecondary)
                )

            Spacer()
        }
    }

    // MARK: - Follow-up chip

    private func followUpChip(_ text: String) -> some View {
        HStack {
            Button {
                viewModel.clearFollowUp()
                Task { await viewModel.send(text) }
            } label: {
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.ana5)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.backgroundTertiary)
                    )
                    .lineLimit(2)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(AppTheme.Motion.standard, value: viewModel.suggestedFollowUp)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.Colors.borderSubtle)
                .frame(height: 1)

            HStack(alignment: .bottom, spacing: AppTheme.Spacing.sm) {
                TextField("Ask about your notes...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .tint(AppTheme.Colors.ana4)

                Button {
                    let text = inputText
                    inputText = ""
                    Task { await viewModel.send(text) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(sendButtonEnabled ? AppTheme.Colors.ana1 : AppTheme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(!sendButtonEnabled)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .background(AppTheme.Colors.backgroundSecondary)
    }

    private var sendButtonEnabled: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isGenerating
    }
}

// MARK: - TypingDotsView

@available(iOS 26, *)
private struct TypingDotsView: View {

    @State private var animating = false

    private let dotCount = 3
    private let dotSize: CGFloat = 7
    private let bounce: CGFloat = -6

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.ana4, AppTheme.Colors.ana5],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: animating ? bounce : 0)
                    .opacity(animating ? 1.0 : 0.35)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - ChatBubbleView

@available(iOS 26, *)
private struct ChatBubbleView: View {

    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(message.content)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundStyle(isUser ? Color.white : AppTheme.Colors.textPrimary)

                if !isUser && !message.relatedTopics.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 9, weight: .semibold))
                            Text("From your notes")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                        .foregroundStyle(AppTheme.Colors.textTertiary)

                        HStack(spacing: AppTheme.Spacing.xs) {
                            ForEach(message.relatedTopics.prefix(2), id: \.self) { topic in
                                Text(topic)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(AppTheme.Colors.ana4)
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.Colors.ana4.opacity(0.12))
                                    )
                            }
                        }
                    }
                    .padding(.top, AppTheme.Spacing.xs)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(isUser ? AppTheme.Colors.ana1 : AppTheme.Colors.backgroundSecondary)
            )
            .frame(maxWidth: UIScreen.main.bounds.width * 0.85, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

// MARK: - Previews

@available(iOS 26, *)
#Preview("Mid-conversation") {
    ChatView(viewModel: ChatViewModel.mock)
}

@available(iOS 26, *)
#Preview("Empty state") {
    ChatView(viewModel: ChatViewModel.mockEmpty)
}
