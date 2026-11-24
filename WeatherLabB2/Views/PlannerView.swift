
import SwiftUI

struct PlannerView: View {

    // MARK: - Dependencies

    let forecast: WeatherForecast

    @StateObject private var model = PlannerViewModel()
    @EnvironmentObject private var theme: AppTheme

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                introductionSection

                activitySelectionSection

                durationSelectionSection

                recommendationSection

                scoringInformationSection
            }
            .padding()
        }
        .background(theme.colors.background)
        .navigationTitle("ATMOS Planner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            model.updateForecast(forecast)
        }
        .onChange(of: forecast) { _, newForecast in
            model.updateForecast(newForecast)
        }
    }

    // MARK: - Introduction

    private var introductionSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(theme.colors.accent)

                Text("SMART ACTIVITY PLANNER")
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundStyle(theme.colors.secondaryText)
            }

            Text("Make the most of the weather.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.colors.primaryText)

            Text("Choose an activity and let ATMOS find the most suitable time based on the available forecast.")
                .font(.subheadline)
                .foregroundStyle(theme.colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Label(
                forecast.location.name,
                systemImage: "location.fill"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(theme.colors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                theme.colors.surfaceElevated,
                in: Capsule()
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Activity selection

    private var activitySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            sectionTitle(
                "Choose your activity",
                subtitle: "Recommendations adapt to your activity."
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(OutdoorActivity.allCases) { activity in

                    let isSelected = model.selectedActivity == activity

                    Button {
                        model.selectedActivity = activity
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {

                            Image(systemName: activity.symbol)
                                .font(.title2)
                                .foregroundStyle(
                                    isSelected
                                    ? theme.colors.accent
                                    : theme.colors.secondaryText
                                )

                            Text(activity.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.colors.primaryText)

                            HStack {
                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.colors.accent)
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 92)
                        .background(
                            theme.colors.surfaceElevated,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected
                                    ? theme.colors.accent
                                    : theme.colors.border,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Duration selection

    private var durationSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            sectionTitle(
                "How long?",
                subtitle: "Choose how much time you want to spend."
            )

            HStack(spacing: 10) {
                ForEach(PlannerDuration.allCases) { duration in

                    let isSelected = model.selectedDuration == duration

                    Button {
                        model.selectedDuration = duration
                    } label: {
                        Text(duration.title)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundStyle(
                                isSelected
                                ? theme.colors.background
                                : theme.colors.primaryText
                            )
                            .background(
                                isSelected
                                ? theme.colors.accent
                                : theme.colors.surfaceElevated,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionTitle(
                "Your best times",
                subtitle: "Ranked using the available hourly weather data."
            )

            if model.isCalculating {
                ProgressView("Analyzing forecast...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let best = model.bestRecommendation {

                bestRecommendationCard(best)

                if !model.alternativeRecommendations.isEmpty {
                    Text("Alternative times")
                        .font(.headline)
                        .foregroundStyle(theme.colors.primaryText)
                        .padding(.top, 6)

                    ForEach(
                        Array(model.alternativeRecommendations.enumerated()),
                        id: \.element.id
                    ) { index, recommendation in
                        alternativeCard(
                            recommendation,
                            number: index + 2
                        )
                    }
                }

            } else {
                ContentUnavailableView(
                    "No suitable time found",
                    systemImage: "cloud.question",
                    description: Text(model.statusMessage)
                )
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Best recommendation card

    private func bestRecommendationCard(
        _ recommendation: WeatherRecommendation
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Label("BEST MATCH", systemImage: "sparkles")
                    .font(.caption.bold())
                    .tracking(1)
                    .foregroundStyle(theme.colors.accent)

                Spacer()

                Text(recommendation.scoreText)
                    .font(.title2.bold())
                    .monospacedDigit()
                    .foregroundStyle(scoreColor(recommendation.score))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(timeRange(recommendation))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.primaryText)

                Text(recommendation.startDate.formatted(
                    .dateTime.weekday(.wide).month(.abbreviated).day()
                ))
                .font(.subheadline)
                .foregroundStyle(theme.colors.secondaryText)
            }

            ProgressView(
                value: recommendation.score,
                total: 100
            )
            .tint(scoreColor(recommendation.score))

            Text(scoreDescription(recommendation.score))
                .font(.subheadline)
                .foregroundStyle(theme.colors.secondaryText)

            Divider()
                .overlay(theme.colors.separator)

            scoreBreakdown(recommendation.breakdown)
        }
        .padding(18)
        .background(
            theme.colors.surfaceElevated,
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.accent.opacity(0.5), lineWidth: 1.5)
        }
    }

    // MARK: - Alternative card

    private func alternativeCard(
        _ recommendation: WeatherRecommendation,
        number: Int
    ) -> some View {

        HStack(spacing: 14) {

            Text("\(number)")
                .font(.headline.bold())
                .foregroundStyle(theme.colors.accent)
                .frame(width: 34, height: 34)
                .background(
                    theme.colors.surface,
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(timeRange(recommendation))
                    .font(.headline)
                    .foregroundStyle(theme.colors.primaryText)

                Text(recommendation.startDate.formatted(
                    .dateTime.weekday(.abbreviated).month(.abbreviated).day()
                ))
                .font(.caption)
                .foregroundStyle(theme.colors.secondaryText)
            }

            Spacer()

            Text(recommendation.scoreText)
                .font(.headline.monospacedDigit())
                .foregroundStyle(scoreColor(recommendation.score))
        }
        .padding(14)
        .background(
            theme.colors.surfaceElevated,
            in: RoundedRectangle(cornerRadius: 15)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(theme.colors.border, lineWidth: 1)
        }
    }

    // MARK: - Score breakdown

    private func scoreBreakdown(
        _ breakdown: WeatherScoreBreakdown
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Score breakdown")
                .font(.headline)
                .foregroundStyle(theme.colors.primaryText)

            scoreRow("Temperature", breakdown.temperature, symbol: "thermometer.medium")

            scoreRow("Precipitation", breakdown.precipitation, symbol: "drop.fill")

            scoreRow("Wind", breakdown.wind, symbol: "wind")

            scoreRow("Weather conditions", breakdown.conditions, symbol: "cloud.sun.fill")
        }
    }

    private func scoreRow(
        _ title: String,
        _ score: Double?,
        symbol: String
    ) -> some View {

        HStack(spacing: 10) {

            Image(systemName: symbol)
                .foregroundStyle(theme.colors.accent)
                .frame(width: 22)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(theme.colors.secondaryText)

            Spacer()

            if let score {
                Text("\(Int(score.rounded()))/100")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(theme.colors.primaryText)
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(theme.colors.warning)
            }
        }
    }

    // MARK: - Scoring information

    private var scoringInformationSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Label("How ATMOS decides", systemImage: "info.circle")
                .font(.headline)
                .foregroundStyle(theme.colors.primaryText)

            Text("ATMOS compares temperature, precipitation, wind and weather conditions. Each factor is weighted according to the selected activity. Missing measurements are excluded from the score.")
                .font(.caption)
                .foregroundStyle(theme.colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text("Recommendations are estimates based on the available SMHI forecast, not guarantees of outdoor conditions.")
                .font(.caption)
                .foregroundStyle(theme.colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            theme.colors.surface,
            in: RoundedRectangle(cornerRadius: 15)
        )
    }

    // MARK: - Helpers

    private func sectionTitle(
        _ title: String,
        subtitle: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(theme.colors.primaryText)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(theme.colors.secondaryText)
        }
    }

    private func timeRange(
        _ recommendation: WeatherRecommendation
    ) -> String {

        let start = recommendation.startDate.formatted(
            date: .omitted,
            time: .shortened
        )

        let end = recommendation.endDate.formatted(
            date: .omitted,
            time: .shortened
        )

        return "\(start) – \(end)"
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return theme.colors.danger
        }
    }

    private func scoreDescription(_ score: Double) -> String {
        switch score {
        case 80...:
            return "Excellent conditions for your selected activity."
        case 60..<80:
            return "Good conditions, with some factors to consider."
        case 40..<60:
            return "Mixed conditions. Check the weather before heading out."
        default:
            return "Less suitable conditions for this activity."
        }
    }
}

// MARK: - Preview

#Preview("ATMOS Planner") {
    NavigationStack {
        PlannerView(
            forecast: WeatherForecast(
                location: Location(
                    name: "Stockholm",
                    latitude: 59.3293,
                    longitude: 18.0686
                ),
                fetchedAt: .now,
                hourly: [],
                daily: []
            )
        )
        .environmentObject(AppTheme())
    }
}
        
