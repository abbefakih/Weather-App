import SwiftUI

struct SearchView: View {
    @StateObject private var model = SearchViewModel()
    @StateObject private var favorites = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("WEATHER / SWEDEN").font(.caption.bold()).tracking(2).foregroundStyle(.secondary)
                    Text("Weather, clearly.").font(.largeTitle.bold())
                    HStack {
                        TextField("Stockholm, Göteborg, Ludvika…", text: $model.query)
                            .textInputAutocapitalization(.words).autocorrectionDisabled()
                            .submitLabel(.search).onSubmit(model.search)
                        Button(action: model.search) { Image(systemName: "magnifyingglass") }
                    }
                    if model.isLoading { ProgressView("Searching…") }
                    if let error = model.errorMessage { Text(error).foregroundStyle(.red) }
                }
                if !model.results.isEmpty {
                    Section("Search results") {
                        ForEach(model.results) { place in
                            NavigationLink(place.name) {
                                ForecastView(location: place, favorites: favorites)
                            }
                        }
                    }
                }
                if !favorites.places.isEmpty {
                    Section("Favorites") {
                        ForEach(favorites.places) { place in
                            NavigationLink(place.name) {
                                ForecastView(location: place, favorites: favorites)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Swedish Weather")
            .toolbar { NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") } }
        }
    }
}
