
import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var theme: AppTheme

    @AppStorage("weather.refreshMinutes")
    private var refreshMinutes = 60

    @AppStorage("weather.celsius")
    private var celsius = true

    var body: some View {
        Form {
            // MARK: - Appearance

            Section {
                Toggle(
                    "Dark mode",
                    isOn: Binding(
                        get: { theme.isDarkMode },
                        set: { theme.isDarkMode = $0 }
                    )
                )
                .tint(theme.colors.accent)

                VStack(alignment: .leading, spacing: 10) {
                    settingLabel(
                        "Colour theme",
                        subtitle: "Choose the atmosphere of your app."
                    )

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 10
                    ) {
                        ForEach(AtmosPalette.allCases) { palette in
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    theme.setPalette(palette)
                                }
                            } label: {
                                HStack(spacing: 9) {
                                    Circle()
                                        .fill(paletteGradient(palette))                                        .frame(width: 25, height: 25)

                                    Text(palette.rawValue)
                                        .font(.subheadline.weight(.semibold))

                                    Spacer(minLength: 0)

                                    if theme.palette == palette {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(theme.colors.accent)
                                    }
                                }
                                .foregroundStyle(theme.colors.primaryText)
                                .padding(11)
                                .frame(maxWidth: .infinity)
                                .background(theme.colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 13)
                                        .stroke(
                                            theme.palette == palette
                                            ? theme.colors.accent
                                            : theme.colors.border,
                                            lineWidth: theme.palette == palette ? 2 : 1
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 5)

                VStack(alignment: .leading, spacing: 10) {
                    settingLabel(
                        "Forecast layout",
                        subtitle: "Choose how weather information is arranged."
                    )

                    ForEach(AtmosLayout.allCases) { layout in
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                theme.setLayout(layout)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: layout.symbol)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(theme.colors.accent)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(layout.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(theme.colors.primaryText)

                                    Text(layout.description)
                                        .font(.caption)
                                        .foregroundStyle(theme.colors.secondaryText)
                                }

                                Spacer()

                                Image(
                                    systemName: theme.layout == layout
                                    ? "largecircle.fill.circle"
                                    : "circle"
                                )
                                .foregroundStyle(
                                    theme.layout == layout
                                    ? theme.colors.accent
                                    : theme.colors.mutedText
                                )
                            }
                            .padding(12)
                            .background(
                                theme.layout == layout
                                ? theme.colors.accent.opacity(0.10)
                                : theme.colors.surface
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                            .overlay {
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(
                                        theme.layout == layout
                                        ? theme.colors.accent.opacity(0.5)
                                        : theme.colors.border,
                                        lineWidth: 1
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 5)

            } header: {
                Text("Appearance")
            } footer: {
                Text("Your appearance and layout choices are shared across the app.")
            }

            // MARK: - Temperature

            Section {
                Toggle("Use Celsius", isOn: $celsius)
                    .tint(theme.colors.accent)

                Text(
                    celsius
                    ? "Temperatures are displayed in Celsius."
                    : "Temperatures are displayed in Fahrenheit."
                )
                .font(.footnote)
                .foregroundStyle(theme.colors.secondaryText)

            } header: {
                Text("Temperature")
            }

            // MARK: - Automatic updates

            Section {
                Picker("Refresh interval", selection: $refreshMinutes) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("3 hours").tag(180)
                }
                .tint(theme.colors.accent)

            } header: {
                Text("Automatic updates")
            } footer: {
                Text("Choose how often the app should refresh weather information.")
            }

            // MARK: - Manual updates

            Section {
                Label {
                    Text("Pull down on a forecast to refresh it manually.")
                        .foregroundStyle(theme.colors.secondaryText)
                } icon: {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(theme.colors.accent)
                }

            } header: {
                Text("Manual updates")
            }

            // MARK: - About

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.title2)
                        .foregroundStyle(theme.colors.accent)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("ATMOS Weather")
                            .font(.headline)
                            .foregroundStyle(theme.colors.primaryText)

                        Text("Weather for a clearer view of your day.")
                            .font(.caption)
                            .foregroundStyle(theme.colors.secondaryText)
                    }
                }
                .padding(.vertical, 4)

                Text("Weather data provided by SMHI Open Data.")
                    .font(.footnote)
                    .foregroundStyle(theme.colors.secondaryText)

            } header: {
                Text("About")
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.colors.background)
        .foregroundStyle(theme.colors.primaryText)
        .tint(theme.colors.accent)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Reusable setting label
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
    
    private func settingLabel(
        _ title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.colors.primaryText)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(theme.colors.secondaryText)
        }
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
            .environmentObject(AppTheme())
    }
}
