
import Foundation

struct SMHIService {

    private let baseURL =
        "https://opendata-download-metfcst.smhi.se/api/category/snow1g/version/1/geotype/point"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session // dependency injection
    }
    // MARK: - Fetch forecast

    func fetchForecast( // hämtar data från SMHI
        latitude: Double,
        longitude: Double
    ) async throws -> [HourlyForecast] {
        // guard = villkoren uppfyllda för att fortsätta
        guard (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            throw WeatherError.invalidCoordinates
        }

        // Use a fixed locale so coordinates always use decimal points.
        let latitudeString = String(
            format: "%.5f",
            locale: Locale(identifier: "en_US_POSIX"),
            latitude
        )

        let longitudeString = String(
            format: "%.5f",
            locale: Locale(identifier: "en_US_POSIX"),
            longitude
        )

        let urlString =
            "\(baseURL)/lon/\(longitudeString)/lat/\(latitudeString)/data.json"
        // följer SMHI:s URL-struktur.
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        // Vi skapar en HTTP-förfrågan.
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.serverError(httpResponse.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(
                SMHIResponse.self,
                from: data
            )

            let forecasts = decoded.timeSeries.compactMap { item -> HourlyForecast? in

                let values = item.data

                let temperature = Self.validValue(
                    values["air_temperature"]
                )

                let windSpeed = Self.validValue(
                    values["wind_speed"]
                )

                let precipitation = Self.validValue(
                    values["precipitation_amount_mean"]
                )
                // omvandlar väder symbolen
                let weatherSymbol = Self.validValue(
                    values["symbol_code"]
                ).map { Int($0.rounded()) }

                return HourlyForecast(
                    time: item.time,
                    temperature: temperature,
                    windSpeed: windSpeed,
                    precipitation: precipitation,
                    weatherSymbol: weatherSymbol
                )
            }

            guard !forecasts.isEmpty else {
                throw WeatherError.noResults
            }

            return forecasts

        } catch let error as WeatherError {
            throw error
        } catch {
            throw WeatherError.decodingFailed
        }
    }

    // MARK: - Build complete forecast

    func forecast(
        for location: Location
    ) async throws -> WeatherForecast {

        let hourly = try await fetchForecast(
            latitude: location.latitude,
            longitude: location.longitude
        )

        let grouped = Dictionary(grouping: hourly) { item in
            String(item.time.prefix(10))
        }

        let daily = grouped.keys.sorted().compactMap { date -> DailyForecast? in

            guard let items = grouped[date],
                  !items.isEmpty else {
                return nil
            }

            let temperatures = items.compactMap(\.temperature)
            let windSpeeds = items.compactMap(\.windSpeed)
            let precipitation = items.compactMap(\.precipitation)

            // Use the first available weather symbol for the day.
            let weatherSymbol = items.first {
                $0.weatherSymbol != nil
            }?.weatherSymbol

            // Each precipitation value represents an interval amount.
            // Sum the available interval amounts for the calendar day.
            let totalPrecipitation: Double? =
                precipitation.isEmpty ? nil : precipitation.reduce(0, +)

            return DailyForecast(
                date: date,
                minTemperature: temperatures.min(),
                maxTemperature: temperatures.max(),
                maxWindSpeed: windSpeeds.max(),
                totalPrecipitation: totalPrecipitation,
                weatherSymbol: weatherSymbol
            )
        }

        guard !daily.isEmpty else {
            throw WeatherError.noResults
        }

        return WeatherForecast(
            location: location,
            fetchedAt: Date(),
            hourly: hourly,
            daily: daily
        )
    }

    // MARK: - filtrerar bort ogiltiga API-värden

    private static func validValue(_ value: Double?) -> Double? {
        guard let value,
              value.isFinite,
              value != 9999 else {
            return nil
        }

        return value
    }
}

// MARK: - SNOW1g JSON response models

private struct SMHIResponse: Decodable {
    let timeSeries: [SMHITimeSeries]
}

private struct SMHITimeSeries: Decodable {
    let time: String
    let data: [String: Double]
}
