import Foundation

final class WeatherRepository {
    private let geocoder = GeocodingService()
    private let service = SMHIService()
    private let cacheKey = "weather.lastForecast"

    func search(_ query: String) async throws -> [Location] { try await geocoder.search(query) }
    func forecast(for location: Location) async throws -> WeatherForecast {
        let result = try await service.forecast(for: location)
        if let data = try? JSONEncoder().encode(result) { UserDefaults.standard.set(data, forKey: cacheKey) }
        return result
    }
    func cachedForecast() -> WeatherForecast? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(WeatherForecast.self, from: data)
    }
}
