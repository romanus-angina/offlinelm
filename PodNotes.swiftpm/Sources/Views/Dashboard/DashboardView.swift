import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@available(iOS 26, *)
struct DashboardView: View {

    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self)  private var router

    @Query(sort: \StudyModule.createdAt, order: .reverse)
    private var modules: [StudyModule]

    @State private var viewModel = DashboardViewModel()

    @Namespace var heroNamespace

    private let gridColumns = [
        GridItem(.adaptive(minimum: 300, maximum: 480), spacing: AppTheme.Spacing.md)
    ]

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
            if modules.isEmpty {
                EmptyStateView(onImport: { viewModel.requestImport() })
            } else {
                moduleGrid
            }
        }
        .navigationTitle("PodNotes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .fileImporter(
            isPresented: $viewModel.isShowingFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            let singleResult: Result<URL, any Error> = result.flatMap { urls in
                if let first = urls.first {
                    return .success(first)
                } else {
                    return .failure(URLError(.fileDoesNotExist))
                }
            }

            if let module = viewModel.handlePickerResult(singleResult, context: context) {
                router.showProcessing(for: module)
            }
        }
        .alert(viewModel.errorTitle, isPresented: $viewModel.isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var moduleGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.md) {
                ForEach(modules) { module in
                    ModuleCardView(
                        module: module,
                        namespace: heroNamespace,
                        onTap: {
                            navigateToModule(module)
                        },
                        onPlay: {
                            router.showPodcast(for: module)
                        }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.delete(module, context: context)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    // Routes to the right destination based on the module's current status.
    private func navigateToModule(_ module: StudyModule) {
        switch module.status {
        case .ready:
            router.showPodcast(for: module)
        case .importing, .processing:
            router.showProcessing(for: module)
        case .failed:
            router.showProcessing(for: module)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { viewModel.requestImport() }) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Import PDF")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Gradients.primary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}
