
import SwiftUI

struct CityComparisonView: View {
    @ObservedObject var favorites: FavoritesViewModel
    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if favorites.places.isEmpty {
                    ContentUnavailableView(
                        "No favorite cities yet",
                        systemImage: "star",
                        description: Text("Add cities to favorites from their forecast pages. They will appear here for comparison.")
                    )
                    .padding(.top, 35)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 260), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(favorites.places) { place in
                            CityComparisonCard(location: place)
                        }
                    }
                }

                Text("Each city is loaded independently from SMHI. Values are shown only when the forecast provides them.")
                    .font(.caption2)
                    .foregroundStyle(theme.colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(theme.colors.background)
        .navigationTitle("City Comparison")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("COMPARE YOUR PLACES")
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(theme.colors.accent)
            Text("Weather, side by side.")
                .font(.largeTitle.bold())
                .foregroundStyle(theme.colors.primaryText)
            Text("See how temperature, wind and precipitation differ between your saved cities.")
                .font(.subheadline)
                .foregroundStyle(theme.colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

private struct CityComparisonCard: View {
    let location: Location

    @EnvironmentObject private var theme: AppTheme
    @AppStorage("weather.celsius") private var celsius = true
    @State private var forecast: WeatherForecast?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let repository = WeatherRepository()
    var body: some View {
           VStack(alignment: .leading, spacing: 13) {
               HStack {
                   VStack(alignment: .leading, spacing: 3) {
                       Text(location.name)
                           .font(.headline.bold())
                           .foregroundStyle(theme.colors.primaryText)
                       Text("SMHI forecast")
                           .font(.caption)
                           .foregroundStyle(theme.colors.secondaryText)
                   }
                   Spacer()
                   Image(systemName: "location.fill")
                       .foregroundStyle(theme.colors.accent)
               }

               if let forecast {
                   HStack(alignment: .firstTextBaseline, spacing: 4) {
                       Text(temperature(forecast.hourly.first?.temperature))
                           .font(.system(size: 34, weight: .bold, design: .rounded))
                           .monospacedDigit()
                           .foregroundStyle(theme.colors.primaryText)
                       Spacer()
                       Image(systemName: symbol(forecast.hourly.first?.weatherSymbol))
                           .font(.system(size: 29))
                           .foregroundStyle(theme.colors.accent)
                   }

                   HStack(spacing: 0) {
                       metric("HIGH", temperature(forecast.daily.first?.maxTemperature), "thermometer.high")
                       Spacer()
                       metric("WIND", wind(forecast.hourly.first?.windSpeed), "wind")
                       Spacer()
                       metric("RAIN", rain(forecast.hourly.first?.precipitation), "drop.fill")
                   }

                   if let updated = forecast.fetchedAt as Date? {
                       Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                           .font(.caption2)
                           .foregroundStyle(theme.colors.secondaryText)
                   }
               } else if isLoading {
                   ProgressView("Loading forecast…")
                       .frame(maxWidth: .infinity, minHeight: 95)
               } else {
                   Label(errorMessage ?? "Forecast unavailable", systemImage: "exclamationmark.triangle")
                       .font(.caption)
                       .foregroundStyle(theme.colors.warning)
                   Button("Try again") { Task { await load() } }
                       .font(.caption.weight(.semibold))
               }
           }
           .padding(15)
           .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
           .overlay {
               RoundedRectangle(cornerRadius: 20, style: .continuous)
                   .stroke(theme.colors.border, lineWidth: 1)
           }
           .task { await load() }
       }

       private func load() async {
           isLoading = true
           errorMessage = nil
           do {
               forecast = try await repository.forecast(for: location)
           } catch {
               errorMessage = error.localizedDescription
           }
           isLoading = false
       }

       private func metric(_ title: String, _ value: String, _ symbol: String) -> some View {
           VStack(alignment: .leading, spacing: 4) {
               Label(title, systemImage: symbol)
                   .font(.system(size: 9, weight: .bold))
                   .foregroundStyle(theme.colors.secondaryText)
               Text(value)
                   .font(.caption.weight(.bold).monospacedDigit())
                   .foregroundStyle(theme.colors.primaryText)
           }
       }

       private func temperature(_ value: Double?) -> String {
           guard let value else { return "—" }
           let shown = celsius ? value : value * 9 / 5 + 32
           return "\(Int(shown.rounded()))°"
       }

       private func wind(_ value: Double?) -> String {
           value.map { String(format: "%.1f", $0) + " m/s" } ?? "—"
       }

       private func rain(_ value: Double?) -> String {
           value.map { String(format: "%.1f", $0) + " mm" } ?? "—"
       }

       private func symbol(_ code: Int?) -> String {
           guard let code else { return "cloud.fill" }
           switch code {
           case 1, 2: return "sun.max.fill"
           case 3, 4, 5: return "cloud.sun.fill"
           case 6, 7, 8: return "cloud.fill"
           case 9, 10, 11: return "cloud.drizzle.fill"
           case 12, 13, 14: return "cloud.rain.fill"
           case 15, 16, 17: return "cloud.snow.fill"
           case 18, 19, 20: return "cloud.heavyrain.fill"
           case 21, 22, 23: return "cloud.bolt.rain.fill"
           default: return "cloud.fill"
           }
       }
   }
