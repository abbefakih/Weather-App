import SwiftUI

struct ForecastView: View {
    let location: Location
    @ObservedObject var favorites: FavoritesViewModel
    @StateObject private var model = ForecastViewModel()

    var body: some View {
        List {
            if model.isLoading { ProgressView("Loading forecast…") }
            if let error = model.errorMessage { Text(error).foregroundStyle(.red) }
            if model.isShowingCache { Label("Showing saved forecast", systemImage: "clock.arrow.circlepath").foregroundStyle(.orange) }
            if let forecast = model.forecast {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(location.name).font(.title2.bold())
                        Text(forecast.hourly.first?.temperature.map { "\\(Int($0.rounded()))°" } ?? "—")
                            .font(.system(size: 54, weight: .semibold, design: .rounded))
                        Text("Last updated: \\(forecast.fetchedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 8)
                    Button {
                        favorites.toggle(location)
                    } label: {
                        Label(favorites.contains(location) ? "Remove favorite" : "Add favorite",
                              systemImage: favorites.contains(location) ? "star.fill" : "star")
                    }
                }
                Section("Next days") {
                    ForEach(forecast.daily) { day in
                        NavigationLink {
                            ForecastDetailView(day: day)
                        } label: {
                            HStack {
                                Text(day.date)
                                Spacer()
                                Text(day.weatherSymbol.map { "W\\($0)" } ?? "—")
                                Text("\\(day.minTemperature.map { Int($0.rounded()) } ?? 0)° / \\(day.maxTemperature.map { Int($0.rounded()) } ?? 0)°")
                            }
                        }
                    }
                }
                Section("Hourly forecast") {
                    ForEach(forecast.hourly) { hour in
                        HStack {
                            Text(hour.time)
                            Spacer()
                            Text(hour.temperature.map { "\\(String(format: "%.1f", $0)) °C" } ?? "—")
                            Text(hour.windSpeed.map { "\\(String(format: "%.1f", $0)) m/s" } ?? "")
                                .foregroundStyle(.secondary)
                        }.font(.subheadline)
                    }
                }
            } else if !model.isLoading {
                ContentUnavailableView("No forecast available", systemImage: "cloud",
                                       description: Text("Connect to the internet and try again."))
            }
        }
        .navigationTitle(location.name)
        .refreshable { await model.load(location) }
        .task { if model.forecast == nil { await model.load(location) } }
    }
}
