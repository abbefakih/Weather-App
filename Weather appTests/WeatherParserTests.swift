import XCTest
@testable import Weather_app

final class WeatherParserTests: XCTestCase {
    func testSMHIJSONDecodesAndTransformsTemperature() throws {
        let json = #"{"timeSeries":[{"validTime":"2026-11-10T12:00:00Z","parameters":[{"name":"t","values":[4.5]},{"name":"ws","values":[3.0]},{"name":"Wsymb2","values":[3.0]}]}]}"#
        let response = try JSONDecoder().decode(SMHIResponse.self, from: Data(json.utf8))
        let place = Location(name: "Stockholm", latitude: 59.33, longitude: 18.06)
        let result = SMHIParser.parse(response, location: place)
        XCTAssertEqual(result.hourly.first?.temperature, 4.5)
        XCTAssertEqual(result.daily.first?.maxTemperature, 4.5)
    }
}
