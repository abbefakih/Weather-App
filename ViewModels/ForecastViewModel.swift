import Foundation

@MainActor
final class ForecastViewModel: ObservableObject {
    @Published private(set) var forecast: WeatherForecast?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var isShowingCache = false
    private let repository = WeatherRepository()

    init() {
        forecast = repository.cachedForecast()
        isShowingCache = forecast != nil
    }
    func load(_ location: Location) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            forecast = try await repository.forecast(for: location)
            isShowingCache = false
        } catch {
            errorMessage = error.localizedDescription
            if forecast == nil { forecast = repository.cachedForecast(); isShowingCache = forecast != nil }
        }
    }
}
