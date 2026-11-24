
import SwiftUI

@main
struct WeatherLabB2App: App {

    @StateObject private var theme = AppTheme()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theme)
        }
    }
}

