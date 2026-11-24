import SwiftUI

struct SettingsView: View {
    @AppStorage("weather.refreshMinutes") private var refreshMinutes = 60
    @AppStorage("weather.celsius") private var celsius = true
    var body: some View {
        Form {
            Picker("Refresh interval", selection: $refreshMinutes) {
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("1 hour").tag(60)
                Text("3 hours").tag(180)
            }
            Toggle("Use Celsius", isOn: $celsius)
            Text("Pull down on a forecast to refresh it manually.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .navigationTitle("Settings")
    }
}
