import Foundation

final class GeocodingService {
    func search(_ text: String) async throws -> [Location] {
        let term = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty,
              let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://www.smhi.se/wpta/backend_solr/autocomplete/search/\\(encoded)")
        else { throw WeatherError.invalidLocation }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WeatherError.badResponse }
        guard (200...299).contains(http.statusCode) else { throw WeatherError.httpStatus(http.statusCode) }
        let json = try JSONSerialization.jsonObject(with: data)
        let objects = Self.findObjects(json)
        let found = objects.compactMap { object -> Location? in
            func number(_ keys: [String]) -> Double? {
                for key in keys {
                    if let n = object[key] as? NSNumber { return n.doubleValue }
                    if let s = object[key] as? String, let n = Double(s) { return n }
                }
                return nil
            }
            let name = (object["name"] as? String) ?? (object["title"] as? String)
                ?? (object["label"] as? String) ?? (object["display_name"] as? String)
            guard let name, let lat = number(["lat", "latitude"]),
                  let lon = number(["lon", "lng", "longitude"]),
                  (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }
            return Location(name: name, latitude: lat, longitude: lon)
        }
        guard !found.isEmpty else { throw WeatherError.noResults }
        return Array(found.prefix(8))
    }

    private static func findObjects(_ value: Any) -> [[String: Any]] {
        if let object = value as? [String: Any] {
            var result: [[String: Any]] = []
            if (object["lat"] != nil || object["latitude"] != nil) &&
               (object["lon"] != nil || object["lng"] != nil || object["longitude"] != nil) {
                result.append(object)
            }
            for child in object.values { result += findObjects(child) }
            return result
        }
        if let array = value as? [Any] { return array.flatMap(findObjects) }
        return []
    }
}
