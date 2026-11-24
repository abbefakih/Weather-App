//
//  AdvancedWeatherDashboard.swift
//  WeatherLabB2
//
//  Created by Abbe Fakih on 2026-11-23.
//

import SwiftUI

/// A compact overview built from the forecast already loaded by ForecastView.
struct AdvancedWeatherDashboard: View {
    let forecast: WeatherForecast

    @EnvironmentObject private var theme: AppTheme
    @AppStorage("weather.celsius") private var celsius = true

    private var nextHour: HourlyForecast? {
        forecast.hourly.first
    }

    private var nextDay: DailyForecast? {
        forecast.daily.first
    }

    private var solar: SolarTimes? {
        SolarCalculator.times(
            latitude: forecast.location.latitude,
            longitude: forecast.location.longitude,
            on: Date()
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TODAY AT A GLANCE")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(theme.colors.secondaryText)
                    Text(forecast.location.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(theme.colors.primaryText)
                }
                Spacer()
                Label("SMHI", systemImage: "checkmark.seal.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.colors.accent)
            }

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbol(for: nextHour?.weatherSymbol))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(theme.colors.accent, theme.colors.secondaryAccent)
                    .font(.system(size: 43))

                VStack(alignment: .leading, spacing: 2) {
                    Text(temperature(nextHour?.temperature))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(theme.colors.primaryText)
                    Text("Next forecast hour")
                        .font(.caption)
                        .foregroundStyle(theme.colors.secondaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Label(wind(nextHour?.windSpeed), systemImage: "wind")
                    Label(rain(nextHour?.precipitation), systemImage: "drop.fill")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.colors.secondaryText)
            }
            .padding(15)
            .background(
                LinearGradient(
                    colors: [
                        theme.colors.accent.opacity(0.17),
                        theme.colors.surfaceElevated
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 19, style: .continuous)
            )

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                metric(
                    title: "TODAY'S HIGH",
                    value: temperature(nextDay?.maxTemperature),
                    symbol: "sun.max.fill",
                    tint: theme.colors.chartColors.first ?? theme.colors.accent
                )
                metric(
                    title: "TODAY'S LOW",
                    value: temperature(nextDay?.minTemperature),
                    symbol: "moon.fill",
                    tint: theme.colors.chartColors.dropFirst().first ?? theme.colors.accent
                )
                metric(
                    title: "WIND",
                    value: wind(nextDay?.maxWindSpeed),
                    symbol: "wind",
                    tint: theme.colors.chartColors.dropFirst(2).first ?? theme.colors.accent
                )
                metric(
                    title: "PRECIPITATION",
                    value: rain(nextDay?.totalPrecipitation),
                    symbol: "drop.fill",
                    tint: theme.colors.chartColors.dropFirst(3).first ?? theme.colors.accent
                )
            }
            HStack(spacing: 0) {
                            solarItem(
                                title: "SUNRISE",
                                value: solar?.sunrise.formatted(date: .omitted, time: .shortened) ?? "—",
                                symbol: "sunrise.fill"
                            )
                            Rectangle()
                                .fill(theme.colors.separator)
                                .frame(width: 1, height: 34)
                            solarItem(
                                title: "SUNSET",
                                value: solar?.sunset.formatted(date: .omitted, time: .shortened) ?? "—",
                                symbol: "sunset.fill"
                            )
                        }
                        .padding(.vertical, 12)
                        .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 16))

                        Text("Sunrise and sunset are astronomically calculated from the location coordinates. Weather metrics come from the available SMHI forecast.")
                            .font(.caption2)
                            .foregroundStyle(theme.colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 23, style: .continuous)
                            .stroke(theme.colors.border, lineWidth: 1)
                    }
                }

                private func metric(title: String, value: String, symbol: String, tint: Color) -> some View {
                    HStack(spacing: 9) {
                        Image(systemName: symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(tint)
                            .frame(width: 25)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.6)
                                .foregroundStyle(theme.colors.secondaryText)
                            Text(value)
                                .font(.subheadline.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(theme.colors.primaryText)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 15))
                }

                private func solarItem(title: String, value: String, symbol: String) -> some View {
                    HStack(spacing: 9) {
                        Image(systemName: symbol)
                            .font(.title3)
                            .foregroundStyle(theme.colors.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.7)
                                .foregroundStyle(theme.colors.secondaryText)
                            Text(value)
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(theme.colors.primaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                }

                private func temperature(_ value: Double?) -> String {
                    guard let value else { return "—" }
                    let converted = celsius ? value : value * 9 / 5 + 32
                    return "\(Int(converted.rounded()))°\(celsius ? "C" : "F")"
                }

                private func wind(_ value: Double?) -> String {
                    value.map { String(format: "%.1f m/s", $0) } ?? "—"
                }

                private func rain(_ value: Double?) -> String {
                    value.map { String(format: "%.1f mm", $0) } ?? "—"
                }

                private func symbol(for code: Int?) -> String {
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

private struct SolarTimes {
    let sunrise: Date
    let sunset: Date
}

/// NOAA-style sunrise/sunset approximation. Results are local Date values
/// and are intentionally labelled as calculated rather than SMHI observations.
private enum SolarCalculator {
    static func times(latitude: Double, longitude: Double, on date: Date) -> SolarTimes? {
        guard (-66.0...66.0).contains(latitude),
              (-180.0...180.0).contains(longitude) else { return nil }

        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        guard let sunrise = solarTime(day: day, latitude: latitude, longitude: longitude, date: date, isSunrise: true),
              let sunset = solarTime(day: day, latitude: latitude, longitude: longitude, date: date, isSunrise: false) else {
            return nil
        }

        return SolarTimes(sunrise: sunrise, sunset: sunset)
    }

    private static func solarTime(day: Int, latitude: Double, longitude: Double, date: Date, isSunrise: Bool) -> Date? {
        let longitudeHour = longitude / 15
        let approximate = Double(day) + ((isSunrise ? 6 : 18) - longitudeHour) / 24
        let meanAnomaly = 0.9856 * approximate - 3.289

        var trueLongitude = meanAnomaly
            + 1.916 * sin(radians(meanAnomaly))
            + 0.020 * sin(2 * radians(meanAnomaly))
            + 282.634
        trueLongitude = normalized(trueLongitude)

        var rightAscension = atan(0.91764 * tan(radians(trueLongitude))) * 180 / .pi
        rightAscension = normalized(rightAscension)
        rightAscension += floor(trueLongitude / 90) * 90 - floor(rightAscension / 90) * 90
        rightAscension /= 15

        let sinDeclination = 0.39782 * sin(radians(trueLongitude))
        let cosDeclination = cos(asin(sinDeclination))
        let latitudeRadians = radians(latitude)

        let cosHourAngle = (
            cos(radians(90.833)) - sinDeclination * sin(latitudeRadians)
        ) / (cosDeclination * cos(latitudeRadians))

        guard (-1...1).contains(cosHourAngle) else { return nil }

        let hourAngle = (isSunrise ? 360 - acos(cosHourAngle) * 180 / .pi : acos(cosHourAngle) * 180 / .pi) / 15
        let localMeanTime = hourAngle + rightAscension - 0.06571 * approximate - 6.622
        let utcHour = (localMeanTime - longitudeHour).truncatingRemainder(dividingBy: 24)
        let normalizedHour = utcHour < 0 ? utcHour + 24 : utcHour

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = utcCalendar.dateComponents([.year, .month, .day], from: date)
        guard let utcMidnight = utcCalendar.date(from: components) else { return nil }
        return utcMidnight.addingTimeInterval(normalizedHour * 3600)
    }

    private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    private static func normalized(_ degrees: Double) -> Double {
        let value = degrees.truncatingRemainder(dividingBy: 360)
        return value < 0 ? value + 360 : value
    }
}

