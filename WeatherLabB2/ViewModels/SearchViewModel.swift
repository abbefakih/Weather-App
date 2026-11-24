
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

    // Swedish quick suggestions
    private let quickCities: [Location] = [
        Location(name: "Stockholm", latitude: 59.3293, longitude: 18.0686),
        Location(name: "Göteborg", latitude: 57.7089, longitude: 11.9746),
        Location(name: "Malmö", latitude: 55.6050, longitude: 13.0038),
        Location(name: "Uppsala", latitude: 59.8586, longitude: 17.6389),
        Location(name: "Ludvika", latitude: 60.1496, longitude: 15.1878),
        Location(name: "Sundsvall", latitude: 62.3908, longitude: 17.3069),
        Location(name: "Södertälje", latitude: 59.1955, longitude: 17.6253),
        Location(name: "Skellefteå", latitude: 64.7507, longitude: 20.9528),
        Location(name: "Strängnäs", latitude: 59.3774, longitude: 17.0312),
        Location(name: "Sala", latitude: 59.9199, longitude: 16.6066),
        Location(name: "Sigtuna", latitude: 59.6173, longitude: 17.7236),
        Location(name: "Kiruna", latitude: 67.8558, longitude: 20.2253)
    ]

    func search() {
        scheduleSearch(delay: 0)
    }

    private func scheduleSearch(
        delay: UInt64 = 350_000_000
    ) {
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

        // Find Swedish local matches for every query length.
        let localMatches = quickCities
            .filter {
                $0.name.range(
                    of: value,
                    options: [
                        .anchored,
                        .caseInsensitive,
                        .diacriticInsensitive
                    ]
                ) != nil
            }
            .sorted {
                rank($0.name, for: value) <
                rank($1.name, for: value)
            }

        // One-character searches use local Swedish suggestions.
        if value.count == 1 {
            results = localMatches
            isLoading = false
            hasSearched = true
            return
        }

        isLoading = true

        searchTask = Task {
            do {
                if delay > 0 {
                    try await Task.sleep(
                        nanoseconds: delay
                    )
                }

                try Task.checkCancellation()

                let remoteResults = try await repository.search(value)

                try Task.checkCancellation()

                // Swedish local suggestions first,
                // followed by API results.
                let combined = localMatches + remoteResults

                var seen = Set<String>()

                results = combined.filter { location in
                    let key = String(
                        format: "%.4f,%.4f",
                        location.latitude,
                        location.longitude
                    )

                    return seen.insert(key).inserted
                }
                .prefix(10)
                .map { $0 }

                hasSearched = true
                errorMessage = nil
                isLoading = false

            } catch is CancellationError {
                // A newer search owns the loading state.

            } catch {
                guard !Task.isCancelled else {
                    return
                }

                // Preserve local Swedish results if the API fails.
                results = localMatches
                errorMessage = error.localizedDescription
                hasSearched = true
                isLoading = false
            }
        }
    }

    // Exact match first, then prefix match, then other matches.
    private func rank(
        _ city: String,
        for query: String
    ) -> Int {
        if city.compare(
            query,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) == .orderedSame {
            return 0
        }

        return 1
    }
}
