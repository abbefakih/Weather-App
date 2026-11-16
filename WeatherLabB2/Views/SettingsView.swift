
import SwiftUI

struct SettingsView: View {

    @AppStorage("weather.refreshMinutes")
    private var refreshMinutes = 60

    @AppStorage("weather.celsius")
    private var celsius = true

    @AppStorage("weather.darkMode")
    private var darkMode = true


    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $darkMode)
            }

            Section("Temperature") {
                Toggle("Use Celsius", isOn: $celsius)

                Text(
                    celsius
                    ? "Temperatures are displayed in Celsius."
                    : "Temperatures are displayed in Fahrenheit."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Automatic updates") {
                Picker(
                    "Refresh interval",
                    selection: $refreshMinutes
                ) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("3 hours").tag(180)
                }

                Label(
                    "Updates every \(refreshDescription)",
                    systemImage: "arrow.clockwise"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Manual updates") {
                Label(
                    "Pull down on a forecast to refresh it manually.",
                    systemImage: "arrow.down"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section {
                Text("Weather data provided by SMHI Open Data.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var refreshDescription: String {
        switch refreshMinutes {
        case 15: return "every 15 minutes"
        case 30: return "every 30 minutes"
        case 60: return "every hour"
        case 180: return "every 3 hours"
        default: return "at the selected interval"
        }
    }
}
