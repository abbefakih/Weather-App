
import Foundation
import Combine

@MainActor
final class PlannerViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var forecast: WeatherForecast?

    @Published var selectedActivity: OutdoorActivity = .walking {
        didSet {
            updateRecommendations()
        }
    }

    @Published var selectedDuration: PlannerDuration = .twoHours {
        didSet {
            updateRecommendations()
        }
    }

    @Published private(set) var recommendations: [WeatherRecommendation] = []

    @Published private(set) var isCalculating = false

    // MARK: - Dependencies

    private let recommendationService = WeatherRecommendationService()

    // MARK: - Computed properties

    var bestRecommendation: WeatherRecommendation? {
        recommendations.first
    }

    var alternativeRecommendations: [WeatherRecommendation] {
        Array(recommendations.dropFirst())
    }

    var hasRecommendations: Bool {
        !recommendations.isEmpty
    }

    var locationName: String {
        forecast?.location.name ?? "Unknown location"
    }

    var statusMessage: String {
        guard forecast != nil else {
            return "Waiting for weather forecast."
        }

        guard !hasRecommendations else {
            return "Recommendations are based on the available hourly forecast."
        }

        return "Not enough weather data to find a suitable time."
    }

    // MARK: - Update forecast

    func updateForecast(_ newForecast: WeatherForecast) {
        forecast = newForecast
        updateRecommendations()
    }

    // MARK: - Calculate recommendations

    func updateRecommendations() {
        guard let forecast else {
            recommendations = []
            return
        }

        isCalculating = true

        recommendations = recommendationService.recommendations(
            from: forecast,
            activity: selectedActivity,
            duration: selectedDuration,
            limit: 3
        )

        isCalculating = false
    }
}

