
import SwiftUI

struct ForecastView: View {

    let location: Location

    @ObservedObject var favorites: FavoritesViewModel
    @StateObject private var model = ForecastViewModel()
    @AppStorage("weather.celsius") private var celsius = true
    @AppStorage("weather.refreshMinutes")
    private var refreshMinutes = 60

    private var isFavorite: Bool {
        favorites.contains(location)
    }

    var body: some View {
        List {

            if model.isLoading && model.forecast == nil {
                Section {
                    ProgressView("Loading weather forecast…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
            }

            if let error = model.errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(
                            "Could not update forecast",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.red)

                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Try again") {
                            Task {
                                await model.refresh(location)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }

            if model.isShowingCache {
                Section {
                    Label(
                        "Showing saved forecast",
                        systemImage: "clock.arrow.circlepath"
                    )
                    .foregroundStyle(.orange)

                    if let lastUpdated = model.lastUpdated {
                        Text(
                            "Last successful update: \(lastUpdated.formatted(date: .abbreviated, time: .shortened))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            if let forecast = model.forecast {

                currentWeatherSection(forecast)

                favoriteSection

                dailyForecastSection(forecast)

                hourlyForecastSection(forecast)

                sourceSection(forecast)

            } else if !model.isLoading && model.errorMessage == nil {

                ContentUnavailableView(
                    "No forecast available",
                    systemImage: "cloud",
                    description: Text(
                        "Search for a location and try loading its forecast again."
                    )
                )
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await model.refresh(location)
        }
        .task {
            await model.load(location)

            model.startAutoRefresh(
                for: location,
                intervalMinutes: refreshMinutes
            )
        }
        .onChange(of: refreshMinutes) { _, newValue in
            model.startAutoRefresh(
                for: location,
                intervalMinutes: newValue
            )
        }
        .onDisappear {
            model.stopAutoRefresh()
        }
    }

    // MARK: - Current weather

    private func currentWeatherSection(
        _ forecast: WeatherForecast
    ) -> some View {

        Section {
            VStack(alignment: .leading, spacing: 12) {

                Text(location.name)
                    .font(.title2.bold())

                HStack(alignment: .center, spacing: 16) {

                    Image(systemName: "cloud.sun.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 48))

                    VStack(alignment: .leading, spacing: 4) {

                        Text(
                            temperatureText(
                                forecast.hourly.first?.temperature
                            )
                        )
                        .font(
                            .system(
                                size: 48,
                                weight: .semibold,
                                design: .rounded
                            )
                        )

                        Text("Forecast temperature")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Label(
                        "Updated",
                        systemImage: "clock"
                    )

                    Spacer()

                    Text(
                        forecast.fetchedAt.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Favorites

    private var favoriteSection: some View {

        Section {
            Button {
                favorites.toggle(location)
            } label: {
                Label(
                    isFavorite ? "Remove from favorites" : "Add to favorites",
                    systemImage: isFavorite ? "star.fill" : "star"
                )
            }
            .tint(isFavorite ? .orange : .blue)
        }
    }

    // MARK: - Daily forecast

    private func dailyForecastSection(
        _ forecast: WeatherForecast
    ) -> some View {

        Section("Next days") {

            if forecast.daily.isEmpty {
                Text("No daily forecast available.")
                    .foregroundStyle(.secondary)
            }

            ForEach(forecast.daily) { day in

                NavigationLink {
                    ForecastDetailView(day: day)
                } label: {

                    HStack(spacing: 12) {

                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate(day.date))
                                .font(.headline)

                            Text("Wind: \(windText(day.maxWindSpeed))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "cloud.sun.fill")
                            .symbolRenderingMode(.multicolor)

                        Text(
                            "\(temperatureText(day.minTemperature)) / \(temperatureText(day.maxTemperature))"
                        )
                        .font(.subheadline.monospacedDigit())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Hourly forecast

    private func hourlyForecastSection(
        _ forecast: WeatherForecast
    ) -> some View {

        Section("Hourly forecast") {

            if forecast.hourly.isEmpty {
                Text("No hourly forecast available.")
                    .foregroundStyle(.secondary)
            }

            ForEach(forecast.hourly) { hour in

                HStack(spacing: 12) {

                    Text(formattedTime(hour.time))
                        .frame(width: 55, alignment: .leading)

                    Image(systemName: "cloud.fill")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(temperatureText(hour.temperature))
                        .fontWeight(.semibold)
                        .frame(width: 65, alignment: .trailing)

                    Text(windText(hour.windSpeed))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 65, alignment: .trailing)
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Source information

    private func sourceSection(
        _ forecast: WeatherForecast
    ) -> some View {

        Section("Forecast information") {

            LabeledContent(
                "Location",
                value: forecast.location.name
            )

            LabeledContent(
                "Latitude",
                value: String(format: "%.4f", forecast.location.latitude)
            )

            LabeledContent(
                "Longitude",
                value: String(format: "%.4f", forecast.location.longitude)
            )

            Text("Weather data provided by SMHI Open Data.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Formatting helpers

    private func temperatureText(_ value: Double?) -> String {
        guard let value else { return "—" }

        let converted = celsius ? value : (value * 9 / 5) + 32
        let unit = celsius ? "°C" : "°F"

        return "\(Int(converted.rounded()))\(unit)"
    }

    private func windText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f m/s", value)
    }

    private func formattedDate(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()

        guard let date = formatter.date(from: value) else {
            return value
        }

        return date.formatted(
            .dateTime.weekday(.wide).month(.abbreviated).day()
        )
    }

    private func formattedTime(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()

        guard let date = formatter.date(from: value) else {
            return value
        }

        return date.formatted(date: .omitted, time: .shortened)
    }
}
