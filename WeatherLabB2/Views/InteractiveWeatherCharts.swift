import SwiftUI
import Charts

struct InteractiveWeatherCharts: View {
    enum Metric: String, CaseIterable, Identifiable {
        case temperature = "Temperature"
        case precipitation = "Rain"
        case wind = "Wind"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .temperature: return "thermometer.medium"
            case .precipitation: return "drop.fill"
            case .wind: return "wind"
            }
        }
        var unit: String {
            switch self {
            case .temperature: return "°"
            case .precipitation: return "mm"
            case .wind: return "m/s"
            }
        }
    }
    
    private struct Point: Identifiable {
        let id: String
        let date: Date
        let value: Double
    }
    
    let forecast: WeatherForecast
    @EnvironmentObject private var theme: AppTheme
    @AppStorage("weather.celsius") private var celsius = true
    @State private var metric: Metric = .temperature
    @State private var selectedDate: Date?
    
    private var points: [Point] {
        forecast.hourly.compactMap { hour in
            guard let date = ISO8601DateFormatter().date(from: hour.time) else { return nil }
            let value: Double?
            switch metric {
            case .temperature:
                guard let raw = hour.temperature else { return nil }
                value = celsius ? raw : raw * 9 / 5 + 32
            case .precipitation:
                value = hour.precipitation
            case .wind:
                value = hour.windSpeed
            }
            guard let value, value.isFinite else { return nil }
            return Point(id: hour.id, date: date, value: value)
        }
    }
    
    private var selectedPoint: Point? {
        guard let selectedDate else { return nil }
        return points.min {
            abs($0.date.timeIntervalSince(selectedDate)) <
                abs($1.date.timeIntervalSince(selectedDate))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("WEATHER ANALYTICS")
                        .font(.caption.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(theme.colors.secondaryText)
                    Text("Interactive forecast")
                        .font(.title3.bold())
                        .foregroundStyle(theme.colors.primaryText)
                }
                Spacer()
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundStyle(theme.colors.accent)
            }
            
            Picker("Weather metric", selection: $metric) {
                ForEach(Metric.allCases) { item in
                    Label(item.rawValue, systemImage: item.symbol).tag(item)
                }
            }
            .pickerStyle(.segmented)
            
            if points.isEmpty {
                ContentUnavailableView(
                    "Chart data unavailable",
                    systemImage: "chart.xyaxis.line",
                    description: Text("There are no valid values for this metric in the current forecast.")
                )
                .frame(minHeight: 170)
            } else {
                Chart {
                    ForEach(points) { point in
                        if metric == .precipitation {
                            BarMark(
                                x: .value("Time", point.date),
                                y: .value(metric.rawValue, point.value)
                            )
                            .foregroundStyle(theme.colors.chartColors.dropFirst().first ?? theme.colors.accent)
                            .cornerRadius(4)
                        } else {
                            AreaMark(
                                x: .value("Time", point.date),
                                y: .value(metric.rawValue, point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        theme.colors.accent.opacity(0.25),
                                        theme.colors.accent.opacity(0.02)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            LineMark(
                                x: .value("Time", point.date),
                                y: .value(metric.rawValue, point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.8, lineCap: .round))
                            .foregroundStyle(theme.colors.chartColors.first ?? theme.colors.accent)
                        }
                        
                        if let selectedPoint, selectedPoint.id == point.id {
                            RuleMark(x: .value("Selected time", point.date))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                .foregroundStyle(theme.colors.secondaryText)
                                .annotation(position: .top, alignment: .leading) {
                                    Text(point.date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2.weight(.bold))
                                        .padding(6)
                                        .background(theme.colors.surfaceElevated, in: Capsule())
                                }
                            PointMark(
                                x: .value("Selected time", point.date),
                                y: .value(metric.rawValue, point.value)
                            )
                            .symbolSize(65)
                            .foregroundStyle(theme.colors.accent)
                        }
                    }
                }
                .chartXSelection(value: $selectedDate)
                .chartYAxisLabel(metric.unit)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .frame(height: 220)
                
                HStack {
                    if let selectedPoint {
                        Label(
                            selectedPoint.date.formatted(date: .abbreviated, time: .shortened),
                            systemImage: "clock"
                        )
                        Spacer()
                        Text(valueText(selectedPoint.value))
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(theme.colors.accent)
                    } else {
                        Text("Drag across the chart to inspect exact values")
                            .font(.caption)
                            .foregroundStyle(theme.colors.secondaryText)
                        Spacer()
                        Text("\(points.count) data points")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(theme.colors.secondaryText)
                    }
                }
            }
        }
        .padding(15)
        .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.colors.border, lineWidth: 1)
        }
        .onChange(of: metric) { _, _ in selectedDate = nil }
    }
    private func valueText(_ value: Double) -> String {
        switch metric {
        case .temperature:
            return "\(value.formatted(.number.precision(.fractionLength(1))))\(celsius ? "°C" : "°F")"
            
        case .precipitation:
            return "\(value.formatted(.number.precision(.fractionLength(1)))) mm"
            
        case .wind:
            return "\(value.formatted(.number.precision(.fractionLength(1)))) m/s"
        }
    }
}
