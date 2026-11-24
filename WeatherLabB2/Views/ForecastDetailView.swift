
    import SwiftUI

    struct ForecastDetailView: View {
        let day: DailyForecast

        @AppStorage("weather.celsius") private var celsius = true

        var body: some View {
            List {
                Section("Weather") {
                    HStack(spacing: 16) {
                        Image(systemName: "cloud.sun.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 42))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate)
                                .font(.title3.bold())

                            Text("Daily forecast")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Temperature") {
                    LabeledContent(
                        "Minimum temperature",
                        value: temperatureText(day.minTemperature)
                    )

                    LabeledContent(
                        "Maximum temperature",
                        value: temperatureText(day.maxTemperature)
                    )
                }

                Section("Wind") {
                    LabeledContent(
                        "Maximum wind speed",
                        value: windText(day.maxWindSpeed)
                    )
                }

                Section("Precipitation") {
                    LabeledContent(
                        "Total precipitation",
                        value: precipitationText(day.totalPrecipitation)
                    )
                }

                Section("Weather information") {
                    LabeledContent(
                        "SMHI weather symbol code",
                        value: day.weatherSymbol.map(String.init) ?? "Unavailable"
                    )

                    Text("Forecast information provided by SMHI Open Data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Day details")
            .navigationBarTitleDisplayMode(.inline)
        }

        private var formattedDate: String {
            let formatter = ISO8601DateFormatter()
            // datum som kommer i ISO 8601-format & görs läsbart för användaren
            guard let date = formatter.date(from: day.date) else {
                return day.date
            }

            return date.formatted(
                .dateTime.weekday(.wide).year().month(.wide).day()
            )
        }

        private func temperatureText(_ value: Double?) -> String {
            guard let value else { return "Unavailable" }

            let converted = celsius ? value : (value * 9 / 5) + 32
            let unit = celsius ? "°C" : "°F"

            return String(format: "%.1f", converted) + " " + unit
        }

        private func windText(_ value: Double?) -> String {
            guard let value else { return "Unavailable" }
            return String(format: "%.1f m/s", value)
        }

        private func precipitationText(_ value: Double?) -> String {
            guard let value else { return "Unavailable" }
            return String(format: "%.1f mm", value)
        }
    }
#Preview("Forecast Detail – Light") {
    NavigationStack {
        ForecastDetailView(
            day: DailyForecast(
                date: "2026-11-23T00:00:00Z",
                minTemperature: 4.0,
                maxTemperature: 12.0,
                maxWindSpeed: 8.5,
                totalPrecipitation: 2.4,
                weatherSymbol: 3
            )
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Forecast Detail – Dark") {
    NavigationStack {
        ForecastDetailView(
            day: DailyForecast(
                date: "2026-11-23T00:00:00Z",
                minTemperature: -3.0,
                maxTemperature: 2.0,
                maxWindSpeed: 14.0,
                totalPrecipitation: 12.0,
                weatherSymbol: 5
            )
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Forecast Detail – Missing Data") {
    NavigationStack {
        ForecastDetailView(
            day: DailyForecast(
                date: "2026-11-23T00:00:00Z",
                minTemperature: nil,
                maxTemperature: nil,
                maxWindSpeed: nil,
                totalPrecipitation: nil,
                weatherSymbol: nil
            )
        )
    }
}
