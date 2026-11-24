import XCTest
@testable import Weather_app

final class WeatherStorageTests: XCTestCase {
    func testForecastCacheRoundTrip() throws {
        let place = Location(name: "Ludvika", latitude: 60.15, longitude: 15.19)
        let forecast = WeatherForecast(location: place, fetchedAt: Date(), hourly: [], daily: [])
        let key = "weather.lastForecast.test"
        let data = try JSONEncoder().encode(forecast)
        UserDefaults.standard.set(data, forKey: key)
        let decoded = try JSONDecoder().decode(WeatherForecast.self, from: UserDefaults.standard.data(forKey: key)!)
        XCTAssertEqual(decoded.location.name, "Ludvika")
        UserDefaults.standard.removeObject(forKey: key)
    }
}
