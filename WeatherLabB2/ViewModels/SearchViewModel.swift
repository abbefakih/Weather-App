
import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {

    @Published var query = "" {
        didSet {
            scheduleSearch()
        }
    }

    @Published private(set) var results: [Location] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasSearched = false
    @Published var errorMessage: String?

    private let repository = WeatherRepository()
    private var searchTask: Task<Void, Never>?

    // Local suggestions make one-letter searches possible.
    private let quickCities: [Location] = [
        Location(name: "Stockholm", latitude: 59.3293, longitude: 18.0686),
        Location(name: "Sundsvall", latitude: 62.3908, longitude: 17.3069),
        Location(name: "Södertälje", latitude: 59.1955, longitude: 17.6253),
        Location(name: "Skellefteå", latitude: 64.7507, longitude: 20.9528),
        Location(name: "Strängnäs", latitude: 59.3774, longitude: 17.0312),
        Location(name: "Sala", latitude: 59.9199, longitude: 16.6066),
        Location(name: "Sigtuna", latitude: 59.6173, longitude: 17.7236),
        Location(name: "Göteborg", latitude: 57.7089, longitude: 11.9746),
        Location(name: "Malmö", latitude: 55.6050, longitude: 13.0038),
        Location(name: "Ludvika", latitude: 60.1496, longitude: 15.1878),
        Location(name: "Uppsala", latitude: 59.8586, longitude: 17.6389),
        Location(name: "Kiruna", latitude: 67.8558, longitude: 20.2253)
    ]

    func search() {
        scheduleSearch(delay: 0)
    }

    private func scheduleSearch(delay: UInt64 = 350_000_000) {
        searchTask?.cancel()

        let value = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        errorMessage = nil
        hasSearched = false

        guard !value.isEmpty else {
            results = []
            isLoading = false
            return
        }

        // A one-character search uses local Swedish suggestions.
        if value.count == 1 {
            results = quickCities.filter {
                $0.name.range(
                    of: value,
                    options: [.anchored, .caseInsensitive, .diacriticInsensitive]
                ) != nil            }
            isLoading = false
            hasSearched = true
            return
        }

        isLoading = true

        searchTask = Task {
            do {
                if delay > 0 {
                    try await Task.sleep(nanoseconds: delay)
                }

                try Task.checkCancellation()

                let response = try await repository.search(value)

                try Task.checkCancellation()

                results = response
                hasSearched = true
                errorMessage = nil
                isLoading = false

            } catch is CancellationError {
                // A newer query has replaced this search.

            } catch {
                guard !Task.isCancelled else { return }

                results = []
                errorMessage = error.localizedDescription
                hasSearched = true
                isLoading = false
            }
        }
    }

}
