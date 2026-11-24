import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [Location] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let repository = WeatherRepository()
    private var task: Task<Void, Never>?

    func search() {
        task?.cancel()
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { errorMessage = "Enter a town or city."; results = []; return }
        isLoading = true; errorMessage = nil
        task = Task {
            defer { isLoading = false }
            do {
                let response = try await repository.search(value)
                guard !Task.isCancelled else { return }
                results = response
            } catch {
                guard !Task.isCancelled else { return }
                results = []; errorMessage = error.localizedDescription
            }
        }
    }
}
