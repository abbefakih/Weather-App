
import Foundation

final class WeatherRepository {
    // instansen för att söka efter platser.
    private let geocoder = GeocodingService()
    private let service = SMHIService()

    private let latestForecastKey = "weather.lastForecast"
    private let cachePrefix = "weather.forecast."

    // MARK: - Location search

    func search(_ query: String) async throws -> [Location] {
        try await geocoder.search(query)
    }

    // MARK: - Fetch forecast

    func forecast(
        for location: Location
    ) async throws -> WeatherForecast {

        let result = try await service.forecast(for: location)

        saveForecast(result)

        return result
    }

    private func saveForecast(_ forecast: WeatherForecast) {
        // MARK Save Forecast to UserDefaults
        let encoder = JSONEncoder()

        guard let data = try? encoder.encode(forecast) else {
            return
        }

        let defaults = UserDefaults.standard // lokala lagringssystem

        defaults.set(data, forKey: cacheKey(for: forecast.location))
        defaults.set(data, forKey: latestForecastKey)
    }

    // MARK: - Load latest cached forecast

    func cachedForecast() -> WeatherForecast? {

        guard let data = UserDefaults.standard.data(
            forKey: latestForecastKey
        ) else {
            return nil
        }

        return try? JSONDecoder().decode(
            WeatherForecast.self,
            from: data
        )
    }

    // MARK: - Load forecast for a specific location

    func cachedForecast(for location: Location) -> WeatherForecast? {

        guard let data = UserDefaults.standard.data(
            forKey: cacheKey(for: location)
        ) else {
            return nil
        }

        return try? JSONDecoder().decode(
            WeatherForecast.self,
            from: data
        )
    }

    // MARK: - Cache key

    private func cacheKey(for location: Location) -> String {

        let latitude = String(
            format: "%.5f",
            locale: Locale(identifier: "en_US_POSIX"),
            location.latitude
        )

        let longitude = String(
            format: "%.5f",
            locale: Locale(identifier: "en_US_POSIX"),
            location.longitude
        )

        return "\(cachePrefix)\(latitude)_\(longitude)"
    }
}
