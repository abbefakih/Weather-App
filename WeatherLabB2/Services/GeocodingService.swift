
import Foundation

final class GeocodingService {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    
    func search(_ text: String) async throws -> [Location] {
        let query = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !query.isEmpty else {
            return []
        }
        
        // First search specifically in Sweden.
        let swedishResults = try await fetchResults(
            query,
            countryCode: "SE"
        )
        
        // Then search internationally.
        let internationalResults = try await fetchResults(
            query,
            countryCode: nil
        )
        
        // Swedish locations always appear first.
        let combined = swedishResults + internationalResults
        
        var seenCoordinates = Set<String>()
        
        return combined.compactMap { result in
            guard (-90...90).contains(result.latitude),
                  (-180...180).contains(result.longitude) else {
                return nil
            }
            
            let coordinateKey = String(
                format: "%.4f,%.4f",
                result.latitude,
                result.longitude
            )
            
            guard seenCoordinates.insert(coordinateKey).inserted else {
                return nil
            }
            
            let displayName = [
                result.name,
                result.admin1,
                result.country
            ]
                .compactMap { $0 }
                .reduce(into: [String]()) { parts, value in
                    if !parts.contains(value) {
                        parts.append(value)
                    }
                }
                .joined(separator: ", ")
            
            return Location(
                name: displayName,
                latitude: result.latitude,
                longitude: result.longitude
            )
        }
        .prefix(10)
        .map { $0 }
    }
    
    private func fetchResults(
        _ query: String,
        countryCode: String?
    ) async throws -> [GeocodingResult] {
        
        var components = URLComponents(
            string: "https://geocoding-api.open-meteo.com/v1/search"
        )
        
        var parameters = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "sv"),
            URLQueryItem(name: "format", value: "json")
        ]
        
        if let countryCode {
            parameters.append(
                URLQueryItem(name: "countryCode", value: countryCode)
            )
        }
        
        components?.queryItems = parameters
        
        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.httpStatus(httpResponse.statusCode)
        }
        
        do {
            let decoded = try JSONDecoder().decode(
                GeocodingResponse.self,
                from: data
            )
            
            return decoded.results ?? []
        } catch {
            throw WeatherError.decodingFailed
        }
    }
}
    

// MARK: - Open-Meteo response models

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]?
}

private struct GeocodingResult: Decodable {
    let name: String
    let latitude: Double
    let longitude: Double
    let admin1: String?
    let country: String?
}
