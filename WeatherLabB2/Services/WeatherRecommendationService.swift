
import Foundation

struct WeatherRecommendationService {

    // MARK: - Activity preferences

    private struct ActivityProfile {
        let idealTemperature: ClosedRange<Double>
        let temperatureWeight: Double
        let precipitationWeight: Double
        let windWeight: Double
        let conditionsWeight: Double
        let windLimit: Double
    }

    private func profile(for activity: OutdoorActivity) -> ActivityProfile {
        switch activity {
        case .walking:
            return ActivityProfile(
                idealTemperature: 15...22,
                temperatureWeight: 0.25,
                precipitationWeight: 0.35,
                windWeight: 0.25,
                conditionsWeight: 0.15,
                windLimit: 10
            )

        case .cycling:
            return ActivityProfile(
                idealTemperature: 12...20,
                temperatureWeight: 0.20,
                precipitationWeight: 0.30,
                windWeight: 0.35,
                conditionsWeight: 0.15,
                windLimit: 8
            )

        case .running:
            return ActivityProfile(
                idealTemperature: 8...16,
                temperatureWeight: 0.25,
                precipitationWeight: 0.30,
                windWeight: 0.30,
                conditionsWeight: 0.15,
                windLimit: 10
            )

        case .photography:
            return ActivityProfile(
                idealTemperature: 5...20,
                temperatureWeight: 0.20,
                precipitationWeight: 0.25,
                windWeight: 0.15,
                conditionsWeight: 0.40,
                windLimit: 12
            )

        case .picnic:
            return ActivityProfile(
                idealTemperature: 18...25,
                temperatureWeight: 0.30,
                precipitationWeight: 0.35,
                windWeight: 0.15,
                conditionsWeight: 0.20,
                windLimit: 7
            )

        case .outing:
            return ActivityProfile(
                idealTemperature: 15...23,
                temperatureWeight: 0.25,
                precipitationWeight: 0.30,
                windWeight: 0.20,
                conditionsWeight: 0.25,
                windLimit: 10
            )
        }
    }

    // MARK: - Public recommendation method

    func recommendations(
        from forecast: WeatherForecast,
        activity: OutdoorActivity,
        duration: PlannerDuration,
        limit: Int = 3
    ) -> [WeatherRecommendation] {

        let profile = profile(for: activity)

        let formatter = ISO8601DateFormatter()

        let validHours = forecast.hourly.compactMap { hour
            -> (forecast: HourlyForecast, date: Date)? in

            guard let date = formatter.date(from: hour.time) else {
                return nil
            }

            return (hour, date)
        }
        .sorted { $0.date < $1.date }

        let requiredHours = duration.rawValue

        guard validHours.count >= requiredHours else {
            return []
        }

        var results: [WeatherRecommendation] = []

        for startIndex in 0...(validHours.count - requiredHours) {

            let window = Array(
                validHours[startIndex..<(startIndex + requiredHours)]
            )

            // Only evaluate complete, consecutive hourly periods.
            let isConsecutive = zip(window, window.dropFirst()).allSatisfy {
                first, second in
                abs(second.date.timeIntervalSince(first.date) - 3600) < 60
            }

            guard isConsecutive else {
                continue
            }

            let temperatureScore = averageScore(
                window.compactMap {
                    $0.forecast.temperature.map {
                        scoreForTemperature($0, idealRange: profile.idealTemperature)
                    }
                }
            )

            let precipitationScore = averageScore(
                window.compactMap {
                    $0.forecast.precipitation.map(scoreForPrecipitation)
                }
            )

            let windScore = averageScore(
                window.compactMap {
                    $0.forecast.windSpeed.map {
                        scoreForWind($0, windLimit: profile.windLimit)
                    }
                }
            )

            let conditionsScore = averageScore(
                window.compactMap {
                    $0.forecast.weatherSymbol.map(scoreForConditions)
                }
            )

            let components: [(Double?, Double)] = [
                (temperatureScore, profile.temperatureWeight),
                (precipitationScore, profile.precipitationWeight),
                (windScore, profile.windWeight),
                (conditionsScore, profile.conditionsWeight)
            ]

            // Missing measurements are excluded.
            // Remaining weights are normalized to avoid inventing data.
            let availableComponents = components.compactMap {
                score, weight -> (Double, Double)? in

                guard let score else {
                    return nil
                }

                return (score, weight)
            }

            let totalWeight = availableComponents.reduce(0.0) {
                $0 + $1.1
            }

            guard totalWeight > 0 else {
                continue
            }

            let totalScore = availableComponents.reduce(0.0) {
                $0 + ($1.0 * $1.1)
            } / totalWeight

            let recommendation = WeatherRecommendation(
                startDate: window[0].date,
                endDate: window[window.count - 1].date.addingTimeInterval(3600),
                score: totalScore,
                breakdown: WeatherScoreBreakdown(
                    temperature: temperatureScore,
                    precipitation: precipitationScore,
                    wind: windScore,
                    conditions: conditionsScore
                )
            )

            results.append(recommendation)
        }

        // Highest score first.
        let sortedResults = results.sorted {
            $0.score > $1.score
        }

        // Avoid alternatives that overlap with an already selected period.
        var selected: [WeatherRecommendation] = []

        for candidate in sortedResults {
            let overlaps = selected.contains {
                candidate.startDate < $0.endDate &&
                candidate.endDate > $0.startDate
            }

            if !overlaps {
                selected.append(candidate)
            }

            if selected.count == max(1, limit) {
                break
            }
        }

        return selected
    }

    // MARK: - Temperature scoring

    private func scoreForTemperature(
        _ temperature: Double,
        idealRange: ClosedRange<Double>
    ) -> Double {

        if idealRange.contains(temperature) {
            return 100
        }

        let distance: Double

        if temperature < idealRange.lowerBound {
            distance = idealRange.lowerBound - temperature
        } else {
            distance = temperature - idealRange.upperBound
        }

        return max(0, 100 - distance * 8)
    }

    // MARK: - Precipitation scoring

    private func scoreForPrecipitation(_ precipitation: Double) -> Double {
        guard precipitation >= 0 else {
            return 0
        }

        return max(0, 100 - precipitation * 100)
    }

    // MARK: - Wind scoring

    private func scoreForWind(
        _ windSpeed: Double,
        windLimit: Double
    ) -> Double {

        guard windSpeed >= 0 else {
            return 0
        }

        if windSpeed <= 3 {
            return 100
        }

        let penalty = (windSpeed - 3) / max(1, windLimit - 3) * 100

        return max(0, 100 - penalty)
    }

    // MARK: - Weather condition scoring

    private func scoreForConditions(_ symbol: Int) -> Double {
        switch symbol {
        case 1, 2:
            return 100

        case 3, 4, 5:
            return 90

        case 6, 7, 8:
            return 75

        case 9, 10, 11:
            return 55

        case 12, 13, 14:
            return 35

        case 15, 16, 17:
            return 45

        case 18, 19, 20:
            return 20

        case 21, 22, 23:
            return 5

        default:
            return 50
        }
    }

    // MARK: - Helpers

    private func averageScore(_ scores: [Double]) -> Double? {
        guard !scores.isEmpty else {
            return nil
        }

        return scores.reduce(0, +) / Double(scores.count)
    }
}
