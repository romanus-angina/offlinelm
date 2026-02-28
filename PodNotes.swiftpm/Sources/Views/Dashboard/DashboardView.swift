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
    @State private var searchText = ""
    @State private var filterStatus: ProcessingStatus? = nil

    @Namespace var heroNamespace

    private let gridColumns = [
        GridItem(.adaptive(minimum: 300, maximum: 480), spacing: AppTheme.Spacing.md)
    ]

    // MARK: - Filtered modules

    private var filteredModules: [StudyModule] {
        var result = modules

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.title.lowercased().contains(query) }
        }

        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        return result
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
            if modules.isEmpty {
                EmptyStateView(onImport: { viewModel.requestImport() })
            } else {
                moduleList
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search notes..."
        )
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

    // MARK: - Module list

    private var moduleList: some View {
        ScrollView {
            // Filter chips
            if modules.count > 3 {
                filterChips
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)
            }

            if filteredModules.isEmpty {
                noResultsView
            } else {
                LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.md) {
                    ForEach(filteredModules) { module in
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
                            if module.isPlayable {
                                Button {
                                    router.showPodcast(for: module)
                                } label: {
                                    Label("Listen", systemImage: "headphones")
                                }

                                Button {
                                    router.showSlides(for: module)
                                } label: {
                                    Label("Study Slides", systemImage: "rectangle.on.rectangle")
                                }

                                Divider()
                            }

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
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                FilterChip(
                    label: "All",
                    isSelected: filterStatus == nil,
                    action: { filterStatus = nil }
                )
                FilterChip(
                    label: "Ready",
                    isSelected: filterStatus == .ready,
                    action: { filterStatus = (filterStatus == .ready) ? nil : .ready }
                )
                FilterChip(
                    label: "Processing",
                    isSelected: filterStatus == .processing,
                    action: { filterStatus = (filterStatus == .processing) ? nil : .processing }
                )
                FilterChip(
                    label: "Failed",
                    isSelected: filterStatus == .failed,
                    action: { filterStatus = (filterStatus == .failed) ? nil : .failed }
                )
            }
        }
    }

    // MARK: - No results

    private var noResultsView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            Text("No matching notes")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text("Try a different search term or filter.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Navigation

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

    // MARK: - Toolbar

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

// MARK: - FilterChip

@available(iOS 26, *)
private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    isSelected ? AppTheme.Colors.backgroundPrimary : AppTheme.Colors.textSecondary
                )
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? AppTheme.Colors.ana4
                                : AppTheme.Colors.backgroundSecondary
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected
                                ? Color.clear
                                : AppTheme.Colors.borderSubtle,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(AppTheme.Motion.snappy, value: isSelected)
    }
}
