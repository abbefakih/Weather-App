import SwiftUI


struct SearchView: View {

    @EnvironmentObject private var theme: AppTheme

    @StateObject private var model = SearchViewModel()
    @StateObject private var favorites = FavoritesViewModel()

    @FocusState private var searchFocused: Bool
    @State private var isStudioTextExpanded = false
    private var selectedLayout: AtmosLayout { theme.layout }
    private var selectedPalette: AtmosPalette { theme.palette }

    private var accentColor: Color { theme.colors.accent }
    private var isDark: Bool { theme.isDarkMode }
    private var background: Color { theme.colors.background }
    private var primaryText: Color { theme.colors.primaryText }
    private var secondaryText: Color { theme.colors.secondaryText }
    private var mutedText: Color { theme.colors.mutedText }
    private var cardBackground: Color { theme.colors.surface }
    private var cardBorder: Color { theme.colors.border }
    private var searchBackground: Color { theme.colors.inputSurface }

    var body: some View {

        NavigationStack {

            ZStack {
                
                background.ignoresSafeArea()
                
                
                
                GeometryReader { geometry in
                    let isLandscape = geometry.size.width > geometry.size.height
                    let horizontalPadding: CGFloat = isLandscape ? 20 : 24

                    ScrollView(showsIndicators: false) {
                        searchContent(
                            width: geometry.size.width - horizontalPadding * 2,
                            height: geometry.size.height
                        )
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, isLandscape ? 12 : 20)
                        .frame(maxWidth: 1100)
                        .frame(maxWidth: .infinity)
                    }
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

            .toolbarColorScheme(isDark ? .dark : .light, for: .navigationBar)
            .toolbarBackground(background, for: .navigationBar)

            .toolbarBackground(.visible, for: .navigationBar)

        }

        .tint(theme.colors.accent)

    }
    
    @ViewBuilder
    private func searchContent(
        width: CGFloat,
        height: CGFloat
    ) -> some View {

        if width > height {
            HStack(alignment: .top, spacing: 32) {

                VStack(alignment: .leading, spacing: 24) {
                    header
                    weatherStudio
                    searchSection
                    discoverSection
                }
                .frame(width: width * 0.40)

                VStack(alignment: .leading, spacing: 24) {
                    if !model.query.isEmpty {
                        resultsSection
                    }

                    if !favorites.places.isEmpty {
                        favoritesSection
                    }

                    footer
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            VStack(alignment: .leading, spacing: 28) {
                header
                weatherStudio
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
        }
    }

    

    @ViewBuilder
    private var mainSections: some View {
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

    private func responsiveContent(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let isLandscape = width > height

        return Group {
            if isLandscape {
                HStack(alignment: .top, spacing: 28) {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        searchSection
                    }
                    .frame(width: width * 0.40, alignment: .topLeading)

                    VStack(alignment: .leading, spacing: 28) {
                        mainSections
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    searchSection
                    mainSections
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 40)
    }

    // MARK: - Header

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .foregroundStyle(accentColor)

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

                .foregroundStyle(accentColor)

            HStack(spacing: 12) {

                Image(systemName: "magnifyingglass")

                    .font(.system(size: 19, weight: .medium))

                    .foregroundStyle(accentColor)

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

                    .foregroundStyle(accentColor)

                Text("Suggestions appear as you type")

                    .foregroundStyle(mutedText)

            }

            .font(.system(size: 11))

        }

    }

    // MARK: - Results

    // MARK: - Weather Studio

    private var weatherStudio: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEATHER STUDIO")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundStyle(accentColor)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            isStudioTextExpanded.toggle()
                        }
                    } label: {
                        Text("Make it yours.")
                            .font(
                                .system(
                                    size: isStudioTextExpanded ? 29 : 21,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(primaryText)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Make it yours")
                    .accessibilityHint("Double tap to enlarge or restore the text")
                }

                Spacer()

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(12)
                    .background(accentColor.opacity(0.13))
                    .clipShape(Circle())
            }

            // Live colour selection
            HStack(spacing: 12) {
                ForEach(AtmosPalette.allCases) { palette in
                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            theme.setPalette(palette)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(
                                    paletteGradient(palette)
                                )
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if selectedPalette == palette {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundStyle(.white)
                                    }
                                }

                            Text(palette.rawValue)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(
                                    selectedPalette == palette
                                    ? primaryText : mutedText
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Layout selection
            HStack(spacing: 8) {
                ForEach(AtmosLayout.allCases) { layout in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            theme.setLayout(layout)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: layoutIcon(layout))
                            Text(layout.rawValue)
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(
                            selectedLayout == layout ? .white : secondaryText
                        )
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedLayout == layout
                            ? accentColor
                            : cardBackground
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Live preview
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("LIVE PREVIEW")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.5)

                    Spacer()

                    Text("\(selectedPalette.rawValue.uppercased()) · \(selectedLayout.rawValue.uppercased())")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                .foregroundStyle(secondaryText)

                previewLayout
                    .animation(.spring(response: 0.4), value: selectedLayout)
                    .animation(.easeInOut(duration: 0.3), value: selectedPalette)
            }
            .padding(13)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(accentColor.opacity(0.25), lineWidth: 1)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    accentColor.opacity(0.12),
                    theme.colors.secondaryAccent.opacity(0.07),
                    cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .overlay {
            RoundedRectangle(cornerRadius: 23)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        }
    }

    private func layoutIcon(_ layout: AtmosLayout) -> String {
        switch layout {
        case .bento: return "square.grid.2x2.fill"
        case .grid: return "square.grid.3x3.fill"
        case .list: return "list.bullet"
        }
    }

    private var previewLayout: some View {
        let cities = [
            ("Stockholm", "cloud.sun.fill", "8°"),
            ("Göteborg", "cloud.rain.fill", "6°"),
            ("Malmö", "sun.max.fill", "11°")
        ]

        return Group {
            switch selectedLayout {
            case .bento:
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        previewWeatherCard(
                            city: cities[0].0,
                            symbol: cities[0].1,
                            temperature: cities[0].2,
                            large: true
                        )
                        previewWeatherCard(
                            city: cities[1].0,
                            symbol: cities[1].1,
                            temperature: cities[1].2,
                            large: false
                        )
                    }

                    previewWeatherCard(
                        city: cities[2].0,
                        symbol: cities[2].1,
                        temperature: cities[2].2,
                        large: false
                    )
                }

            case .grid:
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(cities, id: \.0) { city in
                        previewWeatherCard(
                            city: city.0,
                            symbol: city.1,
                            temperature: city.2,
                            large: false
                        )
                    }
                }

            case .list:
                VStack(spacing: 7) {
                    ForEach(cities, id: \.0) { city in
                        HStack(spacing: 12) {
                            Image(systemName: city.1)
                                .foregroundStyle(accentColor)
                                .frame(width: 25)

                            Text(city.0)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(primaryText)

                            Spacer()

                            Text(city.2)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(primaryText)
                        }
                        .padding(12)
                        .background(accentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    private func paletteGradient(_ palette: AtmosPalette) -> LinearGradient {
        let paletteColors = palette.colors(isDark: theme.isDarkMode)

        return LinearGradient(
            colors: [
                paletteColors.accent,
                paletteColors.secondaryAccent
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func previewWeatherCard(
        city: String,
        symbol: String,
        temperature: String,
        large: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 7) {
                Text(city)
                    .font(.system(size: large ? 13 : 11, weight: .bold))
                    .foregroundStyle(primaryText)

                Image(systemName: symbol)
                    .font(.system(size: large ? 25 : 19))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 2)

            Text(temperature)
                .font(.system(size: large ? 28 : 20, weight: .light, design: .rounded))
                .foregroundStyle(primaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: large ? 91 : 65)
        .background(
            LinearGradient(
                colors: [
                    accentColor.opacity(0.19),
                    theme.colors.secondaryAccent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

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

                        .tint(accentColor)

                        .scaleEffect(0.8)

                } else {

                    Text("\(model.results.count) places")

                        .font(.system(size: 11, weight: .medium))

                        .foregroundStyle(accentColor)
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

                        .fill(accentColor.opacity(0.13))

                        .frame(width: 46, height: 46)

                    Image(systemName: "mappin.and.ellipse")

                        .font(.system(size: 19))

                        .foregroundStyle(accentColor)

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

                    .foregroundStyle(accentColor)

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

            switch selectedLayout {
            case .bento:
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

            case .grid:
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 10
                ) {
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

            case .list:
                VStack(spacing: 9) {
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

                    .foregroundStyle(accentColor)

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

                        .foregroundStyle(accentColor)

                }

            }

            .padding(15)

            .frame(maxWidth: .infinity, alignment: .leading)

            .background(

                LinearGradient(

                    colors: [

                        accentColor.opacity(0.15),

                        theme.colors.secondaryAccent.opacity(0.07)

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

                .foregroundStyle(accentColor)

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

#Preview("01 - Interactive Search") {
    SearchView()
        .environmentObject(AppTheme())
}

#Preview("02 - Light Mode") {
    SearchView()
        .environmentObject(AppTheme())
        .preferredColorScheme(.light)
}

#Preview("03 - Dark Mode") {
    SearchView()
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}

#Preview("7 - Accessibility") {
    SearchView()
        .environmentObject(AppTheme())
        .environment(\.dynamicTypeSize, .xxxLarge)
}

#Preview("8 - Small Text") {
    SearchView()
        .environmentObject(AppTheme())
        .environment(\.dynamicTypeSize, .small)
}

#Preview("9 - Extra Large Text") {
    SearchView()
        .environmentObject(AppTheme())
        .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("10 - Portrait Light") {
    SearchView()
        .environmentObject(AppTheme())
        .preferredColorScheme(.light)
        .previewInterfaceOrientation(.portrait)
}

