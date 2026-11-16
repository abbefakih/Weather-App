import SwiftUI

struct SearchView: View {

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var model = SearchViewModel()

    @StateObject private var favorites = FavoritesViewModel()

    @FocusState private var searchFocused: Bool

    private var isDark: Bool {

        colorScheme == .dark

    }

    private var background: Color {

        isDark

        ? Color(red: 0.035, green: 0.055, blue: 0.105)

        : Color(red: 0.96, green: 0.97, blue: 0.99)

    }

    private var primaryText: Color {

        isDark ? .white : Color.black.opacity(0.88)

    }

    private var secondaryText: Color {

        isDark ? .white.opacity(0.65) : Color.black.opacity(0.65)

    }

    private var mutedText: Color {

        isDark ? .white.opacity(0.45) : Color.black.opacity(0.55)

    }

    private var cardBackground: Color {

        isDark ? .white.opacity(0.065) : .white

    }

    private var cardBorder: Color {

        isDark ? .white.opacity(0.08) : .black.opacity(0.08)

    }

    private var searchBackground: Color {

        isDark ? .white.opacity(0.09) : .white

    }

    var body: some View {

        NavigationStack {

            ZStack {

                background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {

                    VStack(alignment: .leading, spacing: 28) {

                        header

                        searchSection

                        if !model.query.isEmpty {

                            resultsSection

                        } else {

                            discoverSection

                        }

                        if !favorites.places.isEmpty {

                            favoritesSection

                        }

                        footer

                    }

                    .padding(.horizontal, 22)

                    .padding(.top, 18)

                    .padding(.bottom, 40)

                }

            }

            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    NavigationLink {

                        SettingsView()

                    } label: {

                        Image(systemName: "slider.horizontal.3")

                            .font(.system(size: 17, weight: .semibold))

                            .foregroundStyle(primaryText)

                            .padding(11)

                            .background(cardBackground)

                            .clipShape(Circle())

                    }

                }

            }

            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbarBackground(background, for: .navigationBar)

            .toolbarBackground(.visible, for: .navigationBar)

        }

        .tint(.cyan)

    }

    // MARK: - Header

    private var header: some View {

        VStack(alignment: .leading, spacing: 13) {

            HStack(spacing: 8) {

                Image(systemName: "cloud.sun.fill")

                    .foregroundStyle(.cyan)

                Text("ATMOS")

                    .font(.system(size: 12, weight: .black))

                    .tracking(4)

                    .foregroundStyle(secondaryText)

                Spacer()

                HStack(spacing: 6) {

                    Circle()

                        .fill(.green)

                        .frame(width: 7, height: 7)

                    Text("LIVE WEATHER")

                        .font(.system(size: 9, weight: .bold))

                        .tracking(1.2)

                        .foregroundStyle(secondaryText)

                }

            }

            Text("Weather,\nwithout limits.")

                .font(.system(size: 39, weight: .bold, design: .rounded))

                .tracking(-1.5)

                .foregroundStyle(primaryText)

                .fixedSize(horizontal: false, vertical: true)

            Text("Explore the weather anywhere in Sweden.")

                .font(.system(size: 15))

                .foregroundStyle(secondaryText)

        }

        .padding(.top, 12)

    }

    // MARK: - Search

    private var searchSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("FIND YOUR PLACE")

                .font(.system(size: 10, weight: .bold))

                .tracking(2)

                .foregroundStyle(.cyan)

            HStack(spacing: 12) {

                Image(systemName: "magnifyingglass")

                    .font(.system(size: 19, weight: .medium))

                    .foregroundStyle(.cyan)

                TextField(

                    "Search city or location...",

                    text: $model.query

                )

                .font(.system(size: 16))

                .foregroundStyle(primaryText)

                .textInputAutocapitalization(.words)

                .autocorrectionDisabled()

                .submitLabel(.search)

                .focused($searchFocused)

                .onSubmit {

                    model.search()

                    searchFocused = false

                }

                if !model.query.isEmpty {

                    Button {

                        model.query = ""

                        searchFocused = false

                    } label: {

                        Image(systemName: "xmark.circle.fill")

                            .foregroundStyle(mutedText)

                            .font(.system(size: 18))

                    }

                }

            }

            .padding(.horizontal, 17)

            .frame(height: 58)

            .background(searchBackground)

            .clipShape(RoundedRectangle(cornerRadius: 18))

            .overlay {

                RoundedRectangle(cornerRadius: 18)

                    .stroke(cardBorder, lineWidth: 1)

            }

            HStack(spacing: 6) {

                Image(systemName: "sparkles")

                    .foregroundStyle(.cyan)

                Text("Suggestions appear as you type")

                    .foregroundStyle(mutedText)

            }

            .font(.system(size: 11))

        }

    }

    // MARK: - Results

    private var resultsSection: some View {

        VStack(alignment: .leading, spacing: 13) {

            HStack {

                Text("SEARCH RESULTS")

                    .font(.system(size: 10, weight: .bold))

                    .tracking(2)

                    .foregroundStyle(secondaryText)

                Spacer()

                if model.isLoading {

                    ProgressView()

                        .tint(.cyan)

                        .scaleEffect(0.8)

                } else {

                    Text("\(model.results.count) places")

                        .font(.system(size: 11, weight: .medium))

                        .foregroundStyle(.cyan)

                }

            }

            if !model.results.isEmpty {

                VStack(spacing: 9) {

                    ForEach(model.results) { place in

                        locationRow(place)

                    }

                }

            } else if model.isLoading {

                emptyState(

                    icon: "magnifyingglass",

                    title: "Finding places",

                    subtitle: "Searching for matching locations..."

                )

            } else if let error = model.errorMessage {

                emptyState(

                    icon: "exclamationmark.triangle",

                    title: "Search failed",

                    subtitle: error

                )

            } else if model.hasSearched {

                emptyState(

                    icon: "mappin.slash",

                    title: "No places found",

                    subtitle: "Try another city or spelling."

                )

            }

        }

    }

    private func locationRow(_ place: Location) -> some View {
        NavigationLink {

            ForecastView(

                location: place,

                favorites: favorites

            )

        } label: {

            HStack(spacing: 14) {

                ZStack {

                    RoundedRectangle(cornerRadius: 13)

                        .fill(.cyan.opacity(0.13))

                        .frame(width: 46, height: 46)

                    Image(systemName: "mappin.and.ellipse")

                        .font(.system(size: 19))

                        .foregroundStyle(.cyan)

                }

                VStack(alignment: .leading, spacing: 4) {

                    Text(place.name)

                        .font(.system(size: 15, weight: .semibold))

                        .foregroundStyle(primaryText)

                    Text(

                        String(

                            format: "%.3f°, %.3f°",

                            place.latitude,

                            place.longitude

                        )

                    )

                    .font(.system(size: 10, design: .monospaced))

                    .foregroundStyle(mutedText)

                }

                Spacer()

                Image(systemName: "arrow.up.right")

                    .font(.system(size: 13, weight: .bold))

                    .foregroundStyle(.cyan)

            }

            .padding(13)

            .background(cardBackground)

            .clipShape(RoundedRectangle(cornerRadius: 17))

            .overlay {

                RoundedRectangle(cornerRadius: 17)

                    .stroke(cardBorder, lineWidth: 1)

            }

        }

        .buttonStyle(.plain)

    }

    // MARK: - Discover

    private var discoverSection: some View {

        VStack(alignment: .leading, spacing: 15) {

            Text("EXPLORE SWEDEN")

                .font(.system(size: 10, weight: .bold))

                .tracking(2)

                .foregroundStyle(secondaryText)

            HStack(spacing: 10) {

                quickCity(

                    name: "Stockholm",

                    region: "East coast",

                    icon: "building.2.fill",

                    latitude: 59.3293,

                    longitude: 18.0686

                )

                quickCity(

                    name: "Göteborg",

                    region: "West coast",

                    icon: "water.waves",

                    latitude: 57.7089,

                    longitude: 11.9746

                )

            }

            HStack(spacing: 10) {

                quickCity(

                    name: "Malmö",

                    region: "South",

                    icon: "sun.max.fill",

                    latitude: 55.6050,

                    longitude: 13.0038

                )

                quickCity(

                    name: "Ludvika",

                    region: "Dalarna",

                    icon: "mountain.2.fill",

                    latitude: 60.1496,

                    longitude: 15.1878

                )

            }

        }

    }

    private func quickCity(

        name: String,

        region: String,

        icon: String,

        latitude: Double,

        longitude: Double

    ) -> some View {

        let place = Location(

            name: name,

            latitude: latitude,

            longitude: longitude

        )

        return NavigationLink {

            ForecastView(

                location: place,

                favorites: favorites

            )

        } label: {

            VStack(alignment: .leading, spacing: 17) {

                Image(systemName: icon)

                    .font(.system(size: 21))

                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 4) {

                    Text(name)

                        .font(.system(size: 15, weight: .bold))

                        .foregroundStyle(primaryText)

                    Text(region.uppercased())

                        .font(.system(size: 9, weight: .medium))

                        .tracking(1)

                        .foregroundStyle(mutedText)

                }

                HStack {

                    Spacer()

                    Image(systemName: "arrow.up.right")

                        .font(.system(size: 11, weight: .bold))

                        .foregroundStyle(.cyan)

                }

            }

            .padding(15)

            .frame(maxWidth: .infinity, alignment: .leading)

            .background(

                LinearGradient(

                    colors: [

                        Color.cyan.opacity(0.15),

                        Color.blue.opacity(0.07)

                    ],

                    startPoint: .topLeading,

                    endPoint: .bottomTrailing

                )

            )

            .clipShape(RoundedRectangle(cornerRadius: 18))

            .overlay {

                RoundedRectangle(cornerRadius: 18)

                    .stroke(cardBorder, lineWidth: 1)

            }

        }

        .buttonStyle(.plain)

    }

    // MARK: - Favorites

    private var favoritesSection: some View {

        VStack(alignment: .leading, spacing: 13) {

            HStack {

                Text("YOUR FAVORITES")

                    .font(.system(size: 10, weight: .bold))

                    .tracking(2)

                    .foregroundStyle(secondaryText)

                Spacer()

                Image(systemName: "star.fill")

                    .foregroundStyle(.yellow)

            }

            VStack(spacing: 9) {

                ForEach(favorites.places) { place in

                    locationRow(place)

                }

            }

        }

    }

    // MARK: - Empty state

    private func emptyState(

        icon: String,

        title: String,

        subtitle: String

    ) -> some View {

        VStack(spacing: 10) {

            Image(systemName: icon)

                .font(.system(size: 27))

                .foregroundStyle(.cyan)

            Text(title)

                .font(.system(size: 16, weight: .semibold))

                .foregroundStyle(primaryText)

            Text(subtitle)

                .font(.system(size: 12))

                .foregroundStyle(secondaryText)

                .multilineTextAlignment(.center)

        }

        .frame(maxWidth: .infinity)

        .padding(.vertical, 30)

        .padding(.horizontal, 15)

        .background(cardBackground)

        .clipShape(RoundedRectangle(cornerRadius: 18))

    }

    // MARK: - Footer

    private var footer: some View {

        HStack {

            Text("ATMOS")

                .font(.system(size: 10, weight: .black))

                .tracking(3)

            Spacer()

            Text("WEATHER DATA · SWEDEN")

                .font(.system(size: 9, weight: .medium))

                .tracking(1)

        }

        .foregroundStyle(mutedText)

        .padding(.top, 5)

    }

}
