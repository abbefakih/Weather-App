import SwiftUI
import Charts

struct ForecastView: View {
    // MARK: - Dependencies
    let location: Location
    @ObservedObject var favorites: FavoritesViewModel
    @StateObject private var model = ForecastViewModel()
    @EnvironmentObject private var theme: AppTheme
    @State private var selectedDay: DailyForecast?
    @State private var isShowingDayDetail = false
    // MARK: - Preferences
    @AppStorage("weather.celsius") private var celsius = true
    @AppStorage("weather.refreshMinutes") private var refreshMinutes = 60

    private var isFavorite: Bool {
        favorites.contains(location)
    }

    var body: some View {
        GeometryReader { geometry in
            List {
                statusSections

                if let forecast = model.forecast {
                    currentWeatherSection(forecast)
                    favoriteSection
                    Section {
                        WeatherIntelligencePanel(forecast: forecast)
                            .listRowInsets(
                                EdgeInsets(
                                    top: 8,
                                    leading: 0,
                                    bottom: 8,
                                    trailing: 0
                                )
                            )
                            .listRowBackground(Color.clear)
                    }
                    Section {
                        NavigationLink {
                            PlannerView(forecast: forecast)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundStyle(theme.colors.accent)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ATMOS Planner")
                                        .font(.headline)
                                        .foregroundStyle(theme.colors.primaryText)

                                    Text("Find the best time for your outdoor activities")
                                        .font(.caption)
                                        .foregroundStyle(theme.colors.secondaryText)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(theme.colors.accent)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    chartsSection(forecast, availableWidth: geometry.size.width)
                    dailyForecastSection(forecast, availableWidth: geometry.size.width)
                    hourlyForecastSection(forecast)
                    sourceSection(forecast)
                } else if !model.isLoading && model.errorMessage == nil {
                    ContentUnavailableView(
                        "No forecast available",
                        systemImage: "cloud",
                        description: Text("Search for a location and try loading its forecast again.")
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .foregroundStyle(theme.colors.primaryText)
            .tint(theme.colors.accent)
            .navigationDestination(isPresented: $isShowingDayDetail) {
                if let selectedDay {
                    ForecastDetailView(day: selectedDay)
                }
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await model.refresh(location) }
        .task {
            await model.load(location)
            model.startAutoRefresh(for: location, intervalMinutes: refreshMinutes)
        }
        .onChange(of: refreshMinutes) { _, newValue in
            model.startAutoRefresh(for: location, intervalMinutes: newValue)
        }
        .onDisappear { model.stopAutoRefresh() }
    }

    // MARK: - Loading, error and cache states
    @ViewBuilder
    private var statusSections: some View {
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
                    Label("Could not update forecast", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(theme.colors.danger)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.secondaryText)
                    Button("Try again") {
                        Task { await model.refresh(location) }
                    }
                    .tint(theme.colors.accent)
                }
                .padding(.vertical, 6)
            }
        }

        if model.isShowingCache {
            Section {
                Label("Showing saved forecast", systemImage: "clock.arrow.circlepath")
                    .foregroundStyle(theme.colors.warning)
                if let lastUpdated = model.lastUpdated {
                    Text("Last successful update: \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(theme.colors.secondaryText)
                }
            }
        }
    }

    // MARK: - Current conditions
    private func currentWeatherSection(_ forecast: WeatherForecast) -> some View {
        Section("Current conditions") {
            VStack(alignment: .leading, spacing: 16) {
                Text(location.name)
                    .font(.title2.bold())
                    .foregroundStyle(theme.colors.primaryText)

                HStack(spacing: 18) {
                    Image(systemName: "cloud.sun.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 54))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(temperatureText(forecast.hourly.first?.temperature))
                            .font(.system(size: 46, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.colors.accent)
                        Text("Forecast temperature")
                            .font(.caption)
                            .foregroundStyle(theme.colors.secondaryText)
                    }
                    Spacer(minLength: 0)
                }

                Divider().overlay(theme.colors.separator)

                HStack {
                    Label("Updated", systemImage: "clock")
                    Spacer()
                    Text(forecast.fetchedAt.formatted(date: .omitted, time: .shortened))
                }
                .font(.caption)
                .foregroundStyle(theme.colors.secondaryText)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 18))
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
            .tint(isFavorite ? theme.colors.warning : theme.colors.accent)
        }
    }

    // MARK: - Weather Insights
    private func insightsSection(_ forecast: WeatherForecast, availableWidth: CGFloat) -> some View {
        Section {
            let columns = insightColumns(for: availableWidth)
            LazyVGrid(columns: columns, spacing: 12) {
                insightCard(
                    title: "Temperature trend",
                    value: temperatureChangeText(forecast),
                    detail: temperatureTrendDescription(forecast),
                    symbol: "thermometer.medium",
                    color: theme.colors.accent
                )
                insightCard(
                    title: "Rain outlook",
                    value: precipitationSummary(forecast),
                    detail: precipitationDescription(forecast),
                    symbol: "cloud.rain.fill",
                    color: theme.colors.chartColors[safe: 1] ?? theme.colors.accent
                )
                insightCard(
                    title: "Maximum wind",
                    value: maximumWindText(forecast),
                    detail: windDescription(forecast),
                    symbol: "wind",
                    color: theme.colors.chartColors[safe: 2] ?? theme.colors.accent
                )
                insightCard(
                    title: "Week range",
                    value: weeklyRangeText(forecast),
                    detail: weeklyRangeDescription(forecast),
                    symbol: "arrow.up.arrow.down",
                    color: theme.colors.chartColors[safe: 3] ?? theme.colors.accent
                )
            }
            .padding(.vertical, 4)
        } header: {
            sectionHeader("Weather Insights", subtitle: "A quick read of the forecast")
        } footer: {
            Text("Insights are calculated from the forecast values currently available from SMHI.")
        }
    }

    private func insightCard(title: String, value: String, detail: String, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(theme.colors.secondaryText)
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(theme.colors.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(theme.colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(13)
        .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(theme.colors.border, lineWidth: 1)
        }
    }

    // MARK: - Weather Charts
    private func chartsSection(_ forecast: WeatherForecast, availableWidth: CGFloat) -> some View {
        Section {
            switch theme.layout {
            case .bento:
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        temperatureChartCard(forecast, width: 300)
                        precipitationChartCard(forecast, width: 300)
                        windChartCard(forecast, width: 300)
                    }
                    .padding(.vertical, 5)
                }
                .scrollIndicators(.hidden)
            case .grid:
                LazyVGrid(columns: insightColumns(for: availableWidth), spacing: 12) {
                    temperatureChartCard(forecast, width: nil)
                    precipitationChartCard(forecast, width: nil)
                    windChartCard(forecast, width: nil)
                }
                .padding(.vertical, 5)
            case .list:
                VStack(spacing: 12) {
                    temperatureChartCard(forecast, width: nil)
                    precipitationChartCard(forecast, width: nil)
                    windChartCard(forecast, width: nil)
                }
                .padding(.vertical, 5)
            }
        } header: {
            sectionHeader("Weather Charts", subtitle: "Temperature, precipitation and wind")
        }
    }

    private func temperatureChartCard(_ forecast: WeatherForecast, width: CGFloat?) -> some View {
        chartCard(title: "Temperature", subtitle: "Next 24 hours", symbol: "thermometer", width: width) {
            Chart {
                ForEach(Array(forecast.hourly.prefix(24))) { hour in
                    if let value = hour.temperature, let date = parsedDate(hour.time) {
                        AreaMark(x: .value("Time", date), y: .value("Temperature", displayTemperature(value)))
                            .foregroundStyle(theme.colors.accent.opacity(0.13))
                        LineMark(x: .value("Time", date), y: .value("Temperature", displayTemperature(value)))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(theme.colors.chartColors[safe: 0] ?? theme.colors.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                }
            }
            .chartYAxisLabel(celsius ? "°C" : "°F")
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.hour()) } }
            .frame(height: 150)
        }
    }

    private func precipitationChartCard(_ forecast: WeatherForecast, width: CGFloat?) -> some View {
        chartCard(title: "Precipitation", subtitle: "Hourly amount", symbol: "drop.fill", width: width) {
            Chart {
                ForEach(Array(forecast.hourly.prefix(24))) { hour in
                    if let value = hour.precipitation, let date = parsedDate(hour.time) {
                        BarMark(x: .value("Time", date), y: .value("Precipitation", value))
                            .foregroundStyle(theme.colors.chartColors[safe: 1] ?? theme.colors.accent)
                            .cornerRadius(4)
                    }
                }
            }
            .chartYAxisLabel("mm")
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.hour()) } }
            .frame(height: 150)
        }
    }

    private func windChartCard(_ forecast: WeatherForecast, width: CGFloat?) -> some View {
        chartCard(title: "Wind speed", subtitle: "Next 24 hours", symbol: "wind", width: width) {
            Chart {
                ForEach(Array(forecast.hourly.prefix(24))) { hour in
                    if let value = hour.windSpeed, let date = parsedDate(hour.time) {
                        LineMark(x: .value("Time", date), y: .value("Wind", value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(theme.colors.chartColors[safe: 2] ?? theme.colors.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        PointMark(x: .value("Time", date), y: .value("Wind", value))
                            .foregroundStyle(theme.colors.chartColors[safe: 2] ?? theme.colors.accent)
                    }
                }
            }
            .chartYAxisLabel("m/s")
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.hour()) } }
            .frame(height: 150)
        }
    }

    private func chartCard<Content: View>(title: String, subtitle: String, symbol: String, width: CGFloat?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(theme.colors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(theme.colors.primaryText)
                    Text(subtitle).font(.caption).foregroundStyle(theme.colors.secondaryText)
                }
                Spacer(minLength: 0)
            }
            content()
        }
        .padding(14)
        .frame(width: width, alignment: .leading)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(theme.colors.border, lineWidth: 1) }
    }

    // MARK: - Daily forecast

    
    // MARK: - Daily forecast
    private func dailyForecastSection(
        _ forecast: WeatherForecast,
        availableWidth: CGFloat
    ) -> some View {
        Section("Next days") {
            if forecast.daily.isEmpty {
                Text("No daily forecast available.")
                    .foregroundStyle(theme.colors.secondaryText)
            } else {
                switch theme.layout {
                case .bento:
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(forecast.daily) { day in
                                dailyForecastCard(day, width: 210)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .scrollIndicators(.hidden)

                case .grid:
                    LazyVGrid(
                        columns: insightColumns(for: availableWidth),
                        spacing: 12
                    ) {
                        ForEach(forecast.daily) { day in
                            dailyForecastCard(day, width: nil)
                        }
                    }
                    .padding(.vertical, 6)

                case .list:
                    ForEach(forecast.daily) { day in
                        Button {
                            openDayDetail(day)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: weatherSymbol(day.weatherSymbol))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(
                                        theme.colors.accent,
                                        theme.colors.secondaryAccent
                                    )
                                    .font(.system(size: 25))
                                    .frame(width: 38)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formattedDate(day.date))
                                        .font(.headline)
                                        .foregroundStyle(theme.colors.primaryText)

                                    Text("Min: \(temperatureText(day.minTemperature))")
                                        .font(.caption)
                                        .foregroundStyle(theme.colors.secondaryText)
                                }

                                Spacer()

                                Text(temperatureText(day.maxTemperature))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(theme.colors.primaryText)

                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(theme.colors.secondaryText)
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    private func dailyForecastCard(
        _ day: DailyForecast,
        width: CGFloat?
    ) -> some View {
        Button {
            openDayDetail(day)
        } label: {
            VStack(alignment: .leading, spacing: 11) {
                Text(formattedDate(day.date))
                    .font(.headline)
                    .foregroundStyle(theme.colors.primaryText)

                Image(systemName: weatherSymbol(day.weatherSymbol))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        theme.colors.accent,
                        theme.colors.secondaryAccent
                    )
                    .font(.system(size: 32))

                Text("MIN / MAX")
                    .font(.caption)
                    .foregroundStyle(theme.colors.secondaryText)

                Text(
                    "\(temperatureText(day.minTemperature)) / \(temperatureText(day.maxTemperature))"
                )
                .font(.subheadline.bold())
                .monospacedDigit()
                .foregroundStyle(theme.colors.primaryText)

                Label(windText(day.maxWindSpeed), systemImage: "wind")
                    .font(.caption)
                    .foregroundStyle(theme.colors.secondaryText)

                Label(
                    precipitationText(day.totalPrecipitation),
                    systemImage: "drop.fill"
                )
                .font(.caption)
                .foregroundStyle(theme.colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                theme.colors.surface,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.border, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .frame(width: width)
    }
    
    private func openDayDetail(_ day: DailyForecast) {
        selectedDay = day
        isShowingDayDetail = true
    }

    // MARK: - Hourly forecast
    private func hourlyForecastSection(_ forecast: WeatherForecast) -> some View {
        Section("Hourly forecast") {
            if forecast.hourly.isEmpty {
                Text("No hourly forecast available.").foregroundStyle(theme.colors.secondaryText)
            } else {
                ForEach(forecast.hourly) { hour in
                    HStack(spacing: 12) {
                        Text(formattedTime(hour.time)).frame(width: 55, alignment: .leading)
                        Image(systemName: weatherSymbol(hour.weatherSymbol)).foregroundStyle(theme.colors.accent)
                        Spacer()
                        Text(temperatureText(hour.temperature)).fontWeight(.semibold)
                            .frame(width: 65, alignment: .trailing)
                        Text(windText(hour.windSpeed)).font(.caption)
                            .foregroundStyle(theme.colors.secondaryText)
                            .frame(width: 65, alignment: .trailing)
                    }
                    .font(.subheadline)
                    .foregroundStyle(theme.colors.primaryText)
                }
            }
        }
    }

    // MARK: - Source information
    private func sourceSection(_ forecast: WeatherForecast) -> some View {
        Section("Forecast information") {
            LabeledContent("Location", value: forecast.location.name)
            LabeledContent("Latitude", value: String(format: "%.4f", forecast.location.latitude))
            LabeledContent("Longitude", value: String(format: "%.4f", forecast.location.longitude))
            Label("Weather data provided by SMHI Open Data", systemImage: "info.circle")
                .font(.caption).foregroundStyle(theme.colors.secondaryText)
        }
    }

    // MARK: - Insight calculations
    private func temperatureChangeText(_ forecast: WeatherForecast) -> String {
        let values = forecast.hourly.prefix(24).compactMap(\.temperature)
        guard let first = values.first, let last = values.last else { return "—" }
        let change = displayTemperature(last) - displayTemperature(first)
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(Int(change.rounded()))°"
    }

    private func temperatureTrendDescription(_ forecast: WeatherForecast) -> String {
        let values = forecast.hourly.prefix(24).compactMap(\.temperature)
        guard let first = values.first, let last = values.last else { return "Not enough hourly data" }
        if abs(last - first) < 0.5 { return "Temperature stays fairly steady" }
        return last > first ? "Getting warmer over the next hours" : "Getting colder over the next hours"
    }

    private func precipitationSummary(_ forecast: WeatherForecast) -> String {
        let amount = forecast.daily.prefix(7).compactMap(\.totalPrecipitation).reduce(0, +)
        return String(format: "%.1f mm", amount)
    }

    private func precipitationDescription(_ forecast: WeatherForecast) -> String {
        let amount = forecast.daily.prefix(7).compactMap(\.totalPrecipitation).reduce(0, +)
        if amount >= 10 { return "Rain likely in the coming week" }
        if amount > 0 { return "Some precipitation in the forecast" }
        return "No precipitation indicated in available data"
    }

    private func maximumWindText(_ forecast: WeatherForecast) -> String {
        guard let maximum = forecast.daily.prefix(7).compactMap(\.maxWindSpeed).max() else { return "—" }
        return String(format: "%.1f m/s", maximum)
    }

    private func windDescription(_ forecast: WeatherForecast) -> String {
        guard let maximum = forecast.daily.prefix(7).compactMap(\.maxWindSpeed).max() else { return "No wind data available" }
        if maximum >= 14 { return "Strong gusts possible" }
        if maximum >= 8 { return "Breezy conditions possible" }
        return "Generally light to moderate wind"
    }

    private func weeklyRangeText(_ forecast: WeatherForecast) -> String {
        let lows = forecast.daily.prefix(7).compactMap(\.minTemperature)
        let highs = forecast.daily.prefix(7).compactMap(\.maxTemperature)
        guard let low = lows.min(), let high = highs.max() else { return "—" }
        return "\(temperatureText(low)) – \(temperatureText(high))"
    }

    private func weeklyRangeDescription(_ forecast: WeatherForecast) -> String {
        let lows = forecast.daily.prefix(7).compactMap(\.minTemperature)
        let highs = forecast.daily.prefix(7).compactMap(\.maxTemperature)
        guard let low = lows.min(), let high = highs.max() else { return "Not enough daily data" }
        return "Lowest \(temperatureText(low)) · Highest \(temperatureText(high))"
    }

    // MARK: - Layout and styling helpers
    private func insightColumns(for width: CGFloat) -> [GridItem] {
        let minimum: CGFloat = width > 700 ? 260 : 145
        return [GridItem(.adaptive(minimum: minimum), spacing: 12)]
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.headline).foregroundStyle(theme.colors.primaryText)
            Text(subtitle).font(.caption).foregroundStyle(theme.colors.secondaryText)
        }
        .textCase(nil)
    }

    private func displayTemperature(_ value: Double) -> Double {
        celsius ? value : (value * 9 / 5) + 32
    }

    private func temperatureText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(displayTemperature(value).rounded()))°\(celsius ? "C" : "F")"
    }

    private func windText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f m/s", value)
    }

    private func precipitationText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f mm", value)
    }

    private func parsedDate(_ value: String) -> Date? {
        ISO8601DateFormatter().date(from: value)
    }

    private func formattedDate(_ value: String) -> String {
        guard let date = parsedDate(value) else { return value }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func formattedTime(_ value: String) -> String {
        guard let date = parsedDate(value) else { return value }
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func weatherSymbol(_ code: Int?) -> String {
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

// Safe indexing for palette arrays
private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview("Weather Forecast") {
    NavigationStack {
        ForecastView(
            location: Location(name: "Stockholm", latitude: 59.3293, longitude: 18.0686),
            favorites: FavoritesViewModel()
        )
        .environmentObject(AppTheme())
    }
}
