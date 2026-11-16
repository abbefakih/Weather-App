import SwiftUI

struct ContentView: View {

    @AppStorage("weather.darkMode")
    private var darkMode = true

    var body: some View {
        SearchView()
            .preferredColorScheme(darkMode ? .dark : .light)
            .animation(.easeInOut(duration: 0.2), value: darkMode)
    }
}

#Preview {
    ContentView()
}
