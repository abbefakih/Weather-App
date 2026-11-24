import Foundation

final class SMHIService {
    func forecast(for place: Location) async throws -> WeatherForecast {
        let urlText = "https://opendata-download-metfcst.smhi.se/api/category/pmp3g/version/2/geotype/point/lon/\\(place.longitude)/lat/\\(place.latitude)/data.json"
        guard let url = URL(string: urlText) else { throw WeatherError.invalidURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WeatherError.badResponse }
        guard (200...299).contains(http.statusCode) else { throw WeatherError.httpStatus(http.statusCode) }
        let decoded: SMHIResponse
        do { decoded = try JSONDecoder().decode(SMHIResponse.self, from: data) }
        catch { throw WeatherError.decoding }
        return SMHIParser.parse(decoded, location: place)
    }
}

enum SMHIParser {
    static func parse(_ response: SMHIResponse, location: Location) -> WeatherForecast {
        func value(_ key: String, _ item: SMHITimeSeries) -> Double? {
            item.parameters.first(where: { $0.name == key })?.values.first
        }
        let hourly = response.timeSeries.prefix(24).map { item in
            HourlyForecast(time: item.validTime, temperature: value("t", item),
                           windSpeed: value("ws", item), precipitation: value("pmean", item),
                           weatherSymbol: value("Wsymb2", item).map(Int.init))
        }
        let formatter = ISO8601DateFormatter()
        let grouped = Dictionary(grouping: response.timeSeries) { item -> String in
            let date = formatter.date(from: item.validTime) ?? Date.distantPast
            return Calendar(identifier: .gregorian).startOfDay(for: date).formatted(.iso8601.year().month().day())
        }
        let daily = grouped.keys.sorted().prefix(7).compactMap { key -> DailyForecast? in
            guard let items = grouped[key], !items.isEmpty else { return nil }
            let temps = items.compactMap { value("t", $0) }
            let winds = items.compactMap { value("ws", $0) }
            let rain = items.compactMap { value("pmean", $0) }
            let symbols = items.compactMap { value("Wsymb2", $0).map(Int.init) }
            return DailyForecast(date: key, minTemperature: temps.min(), maxTemperature: temps.max(),
                                 weatherSymbol: symbols.first, maxWindSpeed: winds.max(),
                                 totalPrecipitation: rain.reduce(0, +))
        }
        return WeatherForecast(location: location, fetchedAt: Date(), hourly: hourly, daily: Array(daily))
    }
}
