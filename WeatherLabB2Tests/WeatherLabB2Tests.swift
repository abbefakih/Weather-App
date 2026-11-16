
import XCTest
@testable import WeatherLabB2

@MainActor
final class WeatherLabB2Tests: XCTestCase {

    // MARK: - Test area A: Data models and JSON

    func testLocationJSONRoundTrip() throws {
        let location = Location(
            name: "Stockholm",
            latitude: 59.3293,
            longitude: 18.0686
        )

        let data = try JSONEncoder().encode(location)
        let decoded = try JSONDecoder().decode(Location.self, from: data)

        XCTAssertEqual(decoded, location)
        XCTAssertEqual(decoded.name, "Stockholm")
    }

    func testHourlyForecastJSONRoundTrip() throws {
        let original = HourlyForecast(
            time: "2026-11-14T12:00:00Z",
            temperature: 8.5,
            windSpeed: 4.2,
            precipitation: 0.5,
            weatherSymbol: 3
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            HourlyForecast.self, from: data
        )

        XCTAssertEqual(decoded, original)
    }

    func testOptionalWeatherValuesCanBeNil() throws {
        let original = HourlyForecast(
            time: "2026-11-14T12:00:00Z",
            temperature: nil,
            windSpeed: nil,
            precipitation: nil,
            weatherSymbol: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            HourlyForecast.self, from: data
        )

        XCTAssertNil(decoded.temperature)
        XCTAssertNil(decoded.windSpeed)
        XCTAssertNil(decoded.precipitation)
        XCTAssertNil(decoded.weatherSymbol)
    }

    func testMalformedJSONIsRejected() {
        let invalidData = Data("{ invalid json }".utf8)

        XCTAssertThrowsError(
            try JSONDecoder().decode(Location.self, from: invalidData)
        )
    }

    func testCompleteForecastJSONRoundTrip() throws {
        let location = Location(
            name: "Göteborg",
            latitude: 57.7089,
            longitude: 11.9746
        )

        let forecast = WeatherForecast(
            location: location,
            fetchedAt: Date(timeIntervalSince1970: 1_700_000_000),
            hourly: [
                HourlyForecast(
                    time: "2026-11-14T12:00:00Z",
                    temperature: 7.0,
                    windSpeed: 3.0,
                    precipitation: 0.2,
                    weatherSymbol: 2
                )
            ],
            daily: [
                DailyForecast(
                    date: "2026-11-14",
                    minTemperature: 2.0,
                    maxTemperature: 9.0,
                    maxWindSpeed: 5.0,
                    totalPrecipitation: 1.5,
                    weatherSymbol: 2
                )
            ]
        )

        let data = try JSONEncoder().encode(forecast)
        let decoded = try JSONDecoder().decode(
            WeatherForecast.self, from: data
        )

        XCTAssertEqual(decoded, forecast)
        XCTAssertEqual(decoded.daily.first?.minTemperature, 2.0)
        XCTAssertEqual(decoded.daily.first?.maxTemperature, 9.0)
    }

    // MARK: - Test area B: Error handling and validation

    func testInvalidCoordinatesAreRejected() async {
        let service = SMHIService()

        do {
            _ = try await service.fetchForecast(
                latitude: 120,
                longitude: 18
            )
            XCTFail("Invalid latitude should be rejected")
        } catch let error as WeatherError {
            guard case .invalidCoordinates = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testHTTPErrorDescription() {
        let error = WeatherError.serverError(500)

        XCTAssertEqual(
            error.localizedDescription,
            "The server returned HTTP status 500."
        )
    }
}
