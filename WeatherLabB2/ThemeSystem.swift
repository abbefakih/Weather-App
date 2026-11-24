
import SwiftUI
import Combine

// MARK: - Available colour palettes

enum AtmosPalette: String, CaseIterable, Identifiable {
    case deepNavy = "Deep Navy"
    case nordicBlue = "Nordic Blue"
    case softTurquoise = "Soft Turquoise"
    case forestGreen = "Forest Green"
    case warmSand = "Warm Sand"
    case sunsetOrange = "Sunset Orange"

    var id: String { rawValue }

    func colors(isDark: Bool) -> PaletteColors {
        let accent: Color

        switch self {
        case .deepNavy:
            accent = Color(red: 17/255, green: 39/255, blue: 59/255)
        case .nordicBlue:
            accent = Color(red: 54/255, green: 119/255, blue: 157/255)
        case .softTurquoise:
            accent = Color(red: 96/255, green: 179/255, blue: 173/255)
        case .forestGreen:
            accent = Color(red: 132/255, green: 164/255, blue: 123/255)
        case .warmSand:
            accent = Color(red: 235/255, green: 198/255, blue: 121/255)
        case .sunsetOrange:
            accent = Color(red: 216/255, green: 137/255, blue: 83/255)
        }

        let secondary = accent.opacity(isDark ? 0.72 : 0.85)

        return PaletteColors(
            accent: accent,
            secondaryAccent: secondary
        )
    }
}

// MARK: - Palette colours

struct PaletteColors {
    let accent: Color
    let secondaryAccent: Color
}

// MARK: - Forecast layouts

enum AtmosLayout: String, CaseIterable, Identifiable {
    case bento = "Bento"
    case grid = "Grid"
    case list = "List"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .bento: return "square.grid.2x2.fill"
        case .grid: return "square.grid.3x3.fill"
        case .list: return "list.bullet"
        }
    }

    var description: String {
        switch self {
        case .bento:
            return "A balanced overview with larger weather cards."
        case .grid:
            return "Weather information arranged in a grid."
        case .list:
            return "A compact vertical list of weather details."
        }
    }
}

// MARK: - App theme

@MainActor
final class AppTheme: ObservableObject {

    @Published var palette: AtmosPalette {
        didSet {
            UserDefaults.standard.set(
                palette.rawValue,
                forKey: "atmos.selectedPalette"
            )
        }
    }

    @Published var layout: AtmosLayout {
        didSet {
            UserDefaults.standard.set(
                layout.rawValue,
                forKey: "atmos.selectedLayout"
            )
        }
    }

    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(
                isDarkMode,
                forKey: "weather.darkMode"
            )
        }
    }

    init() {
        let savedPalette = UserDefaults.standard.string(
            forKey: "atmos.selectedPalette"
        )

        let savedLayout = UserDefaults.standard.string(
            forKey: "atmos.selectedLayout"
        )

        self.palette = AtmosPalette(rawValue: savedPalette ?? "")
            ?? .deepNavy

        self.layout = AtmosLayout(rawValue: savedLayout ?? "")
            ?? .bento

        self.isDarkMode = UserDefaults.standard.object(
            forKey: "weather.darkMode"
        ) as? Bool ?? true
    }

    var colors: ThemeColors {
        let paletteColors = palette.colors(isDark: isDarkMode)

        return ThemeColors(
            accent: paletteColors.accent,
            secondaryAccent: paletteColors.secondaryAccent,
            background: isDarkMode
                ? Color(red: 0.035, green: 0.055, blue: 0.085)
                : Color(red: 0.96, green: 0.97, blue: 0.98),
            surface: isDarkMode
                ? Color(red: 0.075, green: 0.105, blue: 0.14)
                : Color.white,
            surfaceElevated: isDarkMode
                ? Color(red: 0.11, green: 0.15, blue: 0.19)
                : Color(red: 0.98, green: 0.98, blue: 0.97),
            inputSurface: isDarkMode
                ? Color.white.opacity(0.09)
                : Color.black.opacity(0.045),
            primaryText: isDarkMode
                ? Color.white
                : Color(red: 0.12, green: 0.15, blue: 0.18),
            secondaryText: isDarkMode
                ? Color.white.opacity(0.70)
                : Color.black.opacity(0.65),
            mutedText: isDarkMode
                ? Color.white.opacity(0.45)
                : Color.black.opacity(0.45),
            border: isDarkMode
                ? Color.white.opacity(0.10)
                : Color.black.opacity(0.09),
            separator: isDarkMode
                ? Color.white.opacity(0.12)
                : Color.black.opacity(0.10),
            danger: Color(red: 0.88, green: 0.32, blue: 0.30),
            warning: Color(red: 0.91, green: 0.66, blue: 0.25),
            chartColors: [
                paletteColors.accent,
                Color(red: 0.35, green: 0.65, blue: 0.75),
                Color(red: 0.45, green: 0.68, blue: 0.48),
                Color(red: 0.85, green: 0.62, blue: 0.35)
            ]
        )
    }

    func setPalette(_ newPalette: AtmosPalette) {
        palette = newPalette
    }

    func setLayout(_ newLayout: AtmosLayout) {
        layout = newLayout
    }
}

// MARK: - Shared interface colours

struct ThemeColors {
    let accent: Color
    let secondaryAccent: Color
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let inputSurface: Color
    let primaryText: Color
    let secondaryText: Color
    let mutedText: Color
    let border: Color
    let separator: Color
    let danger: Color
    let warning: Color
    let chartColors: [Color]
}
