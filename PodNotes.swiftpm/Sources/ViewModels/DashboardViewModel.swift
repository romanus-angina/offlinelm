import Foundation
import SwiftData
import Observation
import UniformTypeIdentifiers

@available(iOS 26, *)
@Observable
final class DashboardViewModel {

    // MARK: - Import sheet state

    var isShowingFilePicker = false
    var errorTitle   = ""
    var errorMessage = ""
    var isShowingError = false

    // MARK: - Actions

    func requestImport() {
        isShowingFilePicker = true
    }

    /// Handles the URL from `.fileImporter`, inserts a new StudyModule, and
    /// returns it so the caller can navigate to ProcessingView immediately.
    @discardableResult
    func handlePickerResult(
        _ result: Result<URL, any Error>,
        context: ModelContext
    ) -> StudyModule? {
        switch result {
        case .failure(let error):
            showError("Import failed", error.localizedDescription)
            return nil
        case .success(let url):
            return createModule(from: url, context: context)
        }
    }

    func delete(_ module: StudyModule, context: ModelContext) {
        context.delete(module)
        do {
            try context.save()
        } catch {
            showError("Delete failed", error.localizedDescription)
        }
    }

    // MARK: - Private

    private func createModule(from url: URL, context: ModelContext) -> StudyModule? {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }

        // Read raw PDF bytes while the security-scoped resource is active.
        // This data is stored on the module so the pipeline can process it
        // after navigation, without needing the original URL.
        guard let data = try? Data(contentsOf: url) else {
            showError("Import failed", "Could not read the selected PDF file.")
            return nil
        }

        let name = url
            .deletingPathExtension()
            .lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        let module = StudyModule(
            title: name.isEmpty ? "Untitled" : name,
            status: .importing,
            pdfData: data
        )
        context.insert(module)

        do {
            try context.save()
            return module
        } catch {
            showError("Could not save", error.localizedDescription)
            return nil
        }
    }

    private func showError(_ title: String, _ message: String) {
        errorTitle    = title
        errorMessage  = message
        isShowingError = true
    }
}
