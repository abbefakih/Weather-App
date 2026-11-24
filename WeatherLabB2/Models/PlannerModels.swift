
import Foundation

// MARK: - Activities

enum OutdoorActivity: String, CaseIterable, Identifiable {
    case walking
    case cycling
    case running
    case photography
    case picnic
    case outing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .running: return "Running"
        case .photography: return "Photography"
        case .picnic: return "Picnic"
        case .outing: return "Outdoor outing"
        }
    }

    var symbol: String {
        switch self {
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .running: return "figure.run"
        case .photography: return "camera"
        case .picnic: return "basket"
        case .outing: return "sun.horizon"
        }
    }
}

// MARK: - Activity duration

enum PlannerDuration: Int, CaseIterable, Identifiable {
    case oneHour = 1
    case twoHours = 2
    case threeHours = 3

    var id: Int { rawValue }

    var title: String {
        "\(rawValue) \(rawValue == 1 ? "hour" : "hours")"
    }
}

// MARK: - Score breakdown

struct WeatherScoreBreakdown {
    let temperature: Double?
    let precipitation: Double?
    let wind: Double?
    let conditions: Double?
}

// MARK: - Recommendation

struct WeatherRecommendation: Identifiable {
    let startDate: Date
    let endDate: Date
    let score: Double
    let breakdown: WeatherScoreBreakdown

    var id: Date { startDate }

    var scoreText: String {
        "\(Int(score.rounded()))/100"
    }
}

