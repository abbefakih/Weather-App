import Foundation

struct Location: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double) {
        self.id = id; self.name = name; self.latitude = latitude; self.longitude = longitude
    }
}

struct WeatherForecast: Codable, Equatable {
    let location: Location
    let fetchedAt: Date
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
}
struct HourlyForecast: Codable, Identifiable, Equatable {
    var id: String { time }
    let time: String
    let temperature: Double?
    let windSpeed: Double?
    let precipitation: Double?
    let weatherSymbol: Int?
}
struct DailyForecast: Codable, Identifiable, Equatable {
    var id: String { date }
    let date: String
    let minTemperature: Double?
    let maxTemperature: Double?
    let weatherSymbol: Int?
    let maxWindSpeed: Double?
    let totalPrecipitation: Double?
}

// DTOs matching the SMHI point-forecast JSON structure.
struct SMHIResponse: Decodable { let timeSeries: [SMHITimeSeries] }
struct SMHITimeSeries: Decodable { let validTime: String; let parameters: [SMHIParameter] }
struct SMHIParameter: Decodable { let name: String; let values: [Double] }

enum WeatherError: LocalizedError {
    case invalidLocation, noResults, badResponse, httpStatus(Int), decoding, invalidURL
    var errorDescription: String? {
        switch self {
        case .invalidLocation: return "Enter a valid place name."
        case .noResults: return "No matching Swedish place was found."
        case .badResponse: return "The server returned an unexpected response."
        case .httpStatus(let code): return "The service returned HTTP \\(code)."
        case .decoding: return "The weather response could not be decoded."
        case .invalidURL: return "The request URL is invalid."
        }
    }
}
