
import Foundation

// MARK: - Location

struct Location: Identifiable, Codable, Equatable, Hashable {

    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Complete forecast

struct WeatherForecast: Codable, Equatable {

    let location: Location
    let fetchedAt: Date
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
}

// MARK: - Hourly forecast

struct HourlyForecast: Codable, Equatable, Identifiable {

    var id: String { time }

    let time: String
    let temperature: Double?
    let windSpeed: Double?
    let precipitation: Double?
    let weatherSymbol: Int?
}

// MARK: - Daily forecast

struct DailyForecast: Codable, Equatable, Identifiable {

    var id: String { date }

    let date: String
    let minTemperature: Double?
    let maxTemperature: Double?
    let maxWindSpeed: Double?
    let totalPrecipitation: Double?
    let weatherSymbol: Int?
}

// MARK: - Weather errors

enum WeatherError: Error, LocalizedError {
    case invalidLocation
    case invalidURL
    case badResponse
    case invalidResponse
    case httpStatus(Int)
    case serverError(Int)
    case noResults
    case invalidCoordinates
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidLocation:
            return "Please enter a valid location."
        case .invalidURL:
            return "The request URL is invalid."
        case .badResponse, .invalidResponse:
            return "The server returned an invalid response."
        case .httpStatus(let code), .serverError(let code):
            return "The server returned HTTP status \(code)."
        case .noResults:
            return "No locations were found."
        case .invalidCoordinates:
            return "Invalid geographic coordinates."
        case .decodingFailed:
            return "Could not process weather data."
        }
    }
}
