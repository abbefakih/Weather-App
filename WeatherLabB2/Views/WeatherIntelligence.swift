import SwiftUI

// MARK: - Weather intelligence calculations

/// Insights are derived only from the hourly and daily values returned by SMHI.
enum WeatherInsightsEngine {

    struct Insight: Identifiable {
        let id: String
        let title: String
        let value: String
        let detail: String
        let symbol: String
    }

    struct OutdoorWindow {
        let start: Date
        let end: Date
        let score: Int
        let temperature: Double?
        let precipitation: Double
        let windSpeed: Double?

        var timeRange: String {
            "\(start.formatted(date: .omitted, time: .shortened))–\(end.formatted(date: .omitted, time: .shortened))"
        }
    }

    static func insights(for forecast: WeatherForecast) -> [Insight] {
        let next24 = Array(forecast.hourly.prefix(24))
        let temperatures = next24.compactMap(\.temperature)
        let rainValues = next24.compactMap(\.precipitation)
        let winds = next24.compactMap(\.windSpeed)

        let temperatureInsight: Insight
        if let first = temperatures.first, let last = temperatures.last {
            let delta = last - first
            let detail: String
            if abs(delta) < 1 {
                detail = "Temperaturen väntas vara relativt stabil"
            } else if delta > 0 {
                detail = "Det blir varmare under prognosperioden"
            } else {
                detail = "Det blir kallare under prognosperioden"
            }
            temperatureInsight = Insight(
                id: "temperature",
                title: "Temperaturtrend",
                value: "\(delta > 0 ? "+" : "")\(Int(delta.rounded()))°C",
                detail: detail,
                symbol: "thermometer.medium"
            )
        } else {
            temperatureInsight = Insight(
                id: "temperature",
                title: "Temperaturtrend",
                value: "—",
                detail: "Temperaturdata saknas",
                symbol: "thermometer.medium"
            )
        }

        let rainTotal = rainValues.reduce(0, +)
        let firstRain = next24.first { ($0.precipitation ?? 0) >= 0.1 }
        let rainDetail: String
        if let firstRain, let date = parseDate(firstRain.time) {
            rainDetail = "Nederbörd kan börja omkring \(date.formatted(date: .omitted, time: .shortened))"
        } else if rainValues.isEmpty {
            rainDetail = "Nederbördsdata saknas"
        } else {
            rainDetail = "Ingen nederbörd över 0,1 mm/h i tillgänglig prognos"
        }

        let rainInsight = Insight(
            id: "rain",
            title: "Nederbörd · 24 h",
            value: String(format: "%.1f mm", rainTotal),
            detail: rainDetail,
            symbol: "cloud.rain.fill"
        )

        let maxWind = winds.max()
        let windDetail: String
        if let maxWind {
            if maxWind >= 14 {
                windDetail = "Kraftig vind kan påverka utomhusaktiviteter"
            } else if maxWind >= 8 {
                windDetail = "Det kan kännas blåsigt"
            } else {
                windDetail = "Överlag svag till måttlig vind"
            }
        } else {
            windDetail = "Vinddata saknas"
        }

        let windInsight = Insight(
            id: "wind",
            title: "Högsta vind · 24 h",
            value: maxWind.map { String(format: "%.1f m/s", $0) } ?? "—",
            detail: windDetail,
            symbol: "wind"
        )

        let lows = forecast.daily.prefix(7).compactMap(\.minTemperature)
        let highs = forecast.daily.prefix(7).compactMap(\.maxTemperature)
        let rangeValue: String
        let rangeDetail: String
        if let low = lows.min(), let high = highs.max() {
            rangeValue = "\(Int(low.rounded()))° / \(Int(high.rounded()))°C"
            rangeDetail = "Lägsta respektive högsta temperatur i tillgänglig 7-dagarsprognos"
        } else {
            rangeValue = "—"
            rangeDetail = "Otillräcklig dygnsdata"
        }

        let rangeInsight = Insight(
            id: "weekly-range",
            title: "Veckans spann",
            value: rangeValue,
            detail: rangeDetail,
            symbol: "arrow.up.arrow.down"
        )

        return [temperatureInsight, rainInsight, windInsight, rangeInsight]
    }

    /// Ranks consecutive three-hour windows. This is a transparent heuristic,
    /// not an official SMHI warning or a guarantee of suitable conditions.
    static func bestOutdoorWindow(for forecast: WeatherForecast) -> OutdoorWindow? {
        let hours = Array(forecast.hourly.prefix(24))
        guard hours.count >= 3 else { return nil }

        var best: OutdoorWindow?

        for startIndex in 0...(hours.count - 3) {
            let window = Array(hours[startIndex..<(startIndex + 3)])
            guard let start = parseDate(window[0].time),
                  let last = parseDate(window[2].time) else { continue }

            let rain = window.compactMap(\.precipitation)
            let wind = window.compactMap(\.windSpeed)
            let temperatures = window.compactMap(\.temperature)

            // Missing rain or wind values must not be interpreted as ideal weather.
            guard rain.count == 3, wind.count == 3 else { continue }

            let rainTotal = rain.reduce(0, +)
            let averageWind = wind.reduce(0, +) / Double(wind.count)
            let averageTemperature: Double? = temperatures.isEmpty
                ? nil
                : temperatures.reduce(0, +) / Double(temperatures.count)

            var score = 100.0
            score -= min(rainTotal * 18, 55)
            score -= max(averageWind - 4, 0) * 3.5

            if let averageTemperature {
                if averageTemperature < 0 {
                    score -= min(abs(averageTemperature) * 1.2, 18)
                } else if averageTemperature > 24 {
                    score -= min((averageTemperature - 24) * 1.2, 12)
                }
            }

            let candidate = OutdoorWindow(
                start: start,
                end: last.addingTimeInterval(3600),
                score: max(0, min(100, Int(score.rounded()))),
                temperature: averageTemperature,
                precipitation: rainTotal,
                windSpeed: averageWind
            )

            if best == nil || candidate.score > best!.score {
                best = candidate
            }
        }

        return best
    }

    private static func parseDate(_ value: String) -> Date? {
        ISO8601DateFormatter().date(from: value)
    }
}

// MARK: - Weather Intelligence UI

struct WeatherIntelligencePanel: View {
    let forecast: WeatherForecast

    @EnvironmentObject private var theme: AppTheme
    @AppStorage("weather.celsius") private var celsius = true

    private var insights: [WeatherInsightsEngine.Insight] {
        WeatherInsightsEngine.insights(for: forecast)
    }

    private var outdoorWindow: WeatherInsightsEngine.OutdoorWindow? {
        WeatherInsightsEngine.bestOutdoorWindow(for: forecast)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            header

            if let outdoorWindow {
                outdoorWindowCard(outdoorWindow)
            } else {
                unavailableWindowCard
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 145), spacing: 10)],
                spacing: 10
            ) {
                ForEach(insights) { insight in
                    insightCard(insight)
                }
            }

            Text("Analysen är en vägledande beräkning från tillgängliga SMHI-värden, inte en officiell vädervarning.")
                .font(.caption2)
                .foregroundStyle(theme.colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            theme.colors.surface,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.colors.border, lineWidth: 1)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.colors.accent.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: "sparkles")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(theme.colors.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Weather Intelligence")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(theme.colors.primaryText)

                Text("En smart sammanfattning av prognosen")
                    .font(.caption)
                    .foregroundStyle(theme.colors.secondaryText)
            }

            Spacer()
        }
    }

    private func outdoorWindowCard(
        _ window: WeatherInsightsEngine.OutdoorWindow
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Bästa utomhusfönster", systemImage: "figure.walk")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.colors.primaryText)

                Spacer()

                Text("\(window.score)/100")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(theme.colors.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(theme.colors.accent.opacity(0.12), in: Capsule())
            }

            Text(window.timeRange)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(theme.colors.primaryText)

            HStack(spacing: 14) {
                miniMetric(
                    symbol: "thermometer.medium",
                    value: temperatureValue(window.temperature)
                )
                miniMetric(
                    symbol: "drop.fill",
                    value: String(format: "%.1f mm", window.precipitation)
                )
                miniMetric(
                    symbol: "wind",
                    value: window.windSpeed.map { String(format: "%.1f m/s", $0) } ?? "—"
                )
            }

            Text(scoreDescription(window.score))
                .font(.caption)
                .foregroundStyle(theme.colors.secondaryText)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    theme.colors.accent.opacity(0.16),
                    theme.colors.surfaceElevated
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(theme.colors.accent.opacity(0.25), lineWidth: 1)
        }
    }

    private var unavailableWindowCard: some View {
        Label(
            "Det finns inte tillräckligt med sammanhängande timdata för att föreslå en utomhustid.",
            systemImage: "info.circle"
        )
        .font(.caption)
        .foregroundStyle(theme.colors.secondaryText)
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 15))
    }

    private func insightCard(
        _ insight: WeatherInsightsEngine.Insight
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: insight.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.colors.accent)

            Text(insight.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(theme.colors.secondaryText)

            Text(insight.value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(theme.colors.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(insight.detail)
                .font(.caption2)
                .foregroundStyle(theme.colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 125, alignment: .topLeading)
        .padding(12)
        .background(
            theme.colors.surfaceElevated,
            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(theme.colors.border, lineWidth: 1)
        }
    }

    private func miniMetric(symbol: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(theme.colors.accent)
            Text(value)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(theme.colors.primaryText)
        }
    }

    private func temperatureValue(_ value: Double?) -> String {
        guard let value else { return "—" }
        let shown = celsius ? value : (value * 9 / 5) + 32
        return "\(Int(shown.rounded()))°\(celsius ? "C" : "F")"
    }

    private func scoreDescription(_ score: Int) -> String {
        switch score {
        case 80...100: return "De här timmarna har bäst förutsättningar enligt nederbörd, vind och temperatur."
        case 60..<80: return "Relativt bra förutsättningar, men kontrollera vädret innan du går ut."
        case 40..<60: return "Blandade förhållanden – klä dig efter vädret."
        default: return "Ingen tydligt bra period hittades i den tillgängliga prognosen."
        }
    }
}

#Preview("Weather Intelligence") {
    let sampleLocation = Location(
        name: "Stockholm",
        latitude: 59.3293,
        longitude: 18.0686
    )

    let sampleForecast = WeatherForecast(
        location: sampleLocation,
        fetchedAt: Date(),
        hourly: [],
        daily: []
    )

    WeatherIntelligencePanel(forecast: sampleForecast)
        .environmentObject(AppTheme())
        .padding()
}
