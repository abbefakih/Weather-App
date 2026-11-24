
import Foundation
import Combine

@MainActor
final class ForecastViewModel: ObservableObject {
    // publicerade egenskaper: appen reagerar när värdet ändras
    @Published private(set) var forecast: WeatherForecast?
    @Published private(set) var isLoading = false
    @Published private(set) var isShowingCache = false
    @Published private(set) var lastUpdated: Date?
    @Published var errorMessage: String?

    private let repository = WeatherRepository()

    private var activeRequestID: UUID?
    private var refreshTask: Task<Void, Never>?

    init() {
        if let cached = repository.cachedForecast() {
            forecast = cached
            lastUpdated = cached.fetchedAt
            isShowingCache = true
        }
    }

    // MARK: - Load forecast

    func load(
        _ location: Location,
        forceRefresh: Bool = false
    ) async {

        if !forceRefresh,
           let forecast,
           forecast.location.latitude == location.latitude,
           forecast.location.longitude == location.longitude {
            return
        }

        let requestID = UUID()
        activeRequestID = requestID

        isLoading = true
        errorMessage = nil

        defer {
            if activeRequestID == requestID {
                isLoading = false
                activeRequestID = nil
            }
        }

        do {
            let result = try await repository.forecast(for: location)

            guard activeRequestID == requestID else {
                return
            }

            forecast = result
            lastUpdated = result.fetchedAt
            isShowingCache = false

        } catch {
            guard activeRequestID == requestID else {
                return
            }

            errorMessage = error.localizedDescription

            if let current = forecast,
               current.location.latitude == location.latitude,
               current.location.longitude == location.longitude {
                isShowingCache = true
            } else {
                forecast = nil
                lastUpdated = nil
                isShowingCache = false
            }
        }
    }

    // MARK: - Manual refresh

    func refresh(_ location: Location) async {
        await load(location, forceRefresh: true)
    }

    // MARK: - Automatic refresh

    func startAutoRefresh(
        for location: Location,
        intervalMinutes: Int
    ) {
        stopAutoRefresh()

        guard intervalMinutes > 0 else {
            return
        }

        let intervalNanoseconds =
            UInt64(intervalMinutes) * 60 * 1_000_000_000

        refreshTask = Task { [weak self] in // förhindrar minnesläckor.
            while !Task.isCancelled {
                do {
                    try await Task.sleep(
                        nanoseconds: intervalNanoseconds
                    )
                } catch {
                    break
                }

                guard !Task.isCancelled,
                      let self else {
                    break
                }

                await self.refresh(location)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func clearError() {
        errorMessage = nil
    }
}
