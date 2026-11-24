import SwiftUI

struct ForecastDetailView: View {
    let day: DailyForecast
    var body: some View {
        List {
            LabeledContent("Date", value: day.date)
            LabeledContent("Minimum", value: day.minTemperature.map { "\\(String(format: "%.1f", $0)) °C" } ?? "—")
            LabeledContent("Maximum", value: day.maxTemperature.map { "\\(String(format: "%.1f", $0)) °C" } ?? "—")
            LabeledContent("Weather symbol", value: day.weatherSymbol.map(String.init) ?? "—")
            LabeledContent("Maximum wind", value: day.maxWindSpeed.map { "\\(String(format: "%.1f", $0)) m/s" } ?? "—")
            LabeledContent("Precipitation", value: day.totalPrecipitation.map { "\\(String(format: "%.1f", $0)) mm" } ?? "—")
        }
        .navigationTitle("Day details")
    }
}
