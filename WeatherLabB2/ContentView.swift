
import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        SearchView()
            .preferredColorScheme(
                theme.isDarkMode ? .dark : .light
            )
            .animation(
                .easeInOut(duration: 0.25),
                value: theme.isDarkMode
            )
    }
}

#Preview {
    ContentView()
        .environmentObject(AppTheme())
}
