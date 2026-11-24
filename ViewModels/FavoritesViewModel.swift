import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var places: [Location] = []
    private let key = "weather.favorites"
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Location].self, from: data) { places = saved }
    }
    func contains(_ place: Location) -> Bool { places.contains { $0.name == place.name } }
    func toggle(_ place: Location) {
        if contains(place) { places.removeAll { $0.name == place.name } }
        else { places.append(place) }
        if let data = try? JSONEncoder().encode(places) { UserDefaults.standard.set(data, forKey: key) }
    }
}
