import Foundation
import UIKit

struct AIPlantCandidate: Codable, Identifiable, Hashable {
    let speciesID: String?
    let commonName: String
    let latinName: String?
    let confidence: Double
    let reason: String?

    var id: String { speciesID ?? commonName }
}

struct PlantIdentification: Codable {
    let candidates: [AIPlantCandidate]
    let uncertainty: String
    let needsAnotherPhoto: Bool
}

struct GeneratedCareProfile: Decodable { let requirements: String }

struct DiagnosisHypothesis: Codable, Identifiable {
    let title: String
    let likelihood: String
    let evidence: String
    let safeChecks: [String]
    var id: String { title }
}

struct PlantDiagnosis: Codable {
    let hypotheses: [DiagnosisHypothesis]
    let missingInformation: [String]
    let uncertainty: String
}

enum LocalPlantAIError: LocalizedError {
    case unavailable
    case invalidImage
    case server(String)

    var errorDescription: String? {
        switch self {
        case .unavailable: "Nie udało się połączyć z lokalnym serwerem AI. Połącz się z domowym Wi-Fi lub Tailscale."
        case .invalidImage: "Nie udało się przygotować zdjęcia. Wybierz je ponownie."
        case .server(let message): message
        }
    }
}

actor LocalPlantAIClient {
    static let shared = LocalPlantAIClient()
    // Serwer jest dostępny wyłącznie w prywatnej sieci LAN/Tailscale, bez płatnego API.
    private let baseURLs = [
        URL(string: "https://malina.tail384b18.ts.net/ai")!,
        URL(string: "http://192.168.1.218:8788")!
    ]

    func identify(image: UIImage) async throws -> PlantIdentification {
        let body = try imagePayload(image)
        return try await request(path: "/v1/identify", body: body)
    }

    func sharedAtlas() async throws -> SharedAtlasResponse {
        try await request(path: "/v1/atlas", body: [:], method: "GET")
    }

    func careProfile(speciesName: String) async throws -> GeneratedCareProfile {
        try await request(path: "/v1/care-profile", body: ["speciesName": speciesName])
    }

    func publishSpecies(name: String, requirements: String, source: String, image: UIImage?) async throws -> SharedAtlasPublication {
        var body: [String: Any] = ["name": name, "requirements": requirements, "source": source, "shareConsent": true]
        if let image { body["image"] = try PlantPhotos.jpeg(image, side: 320).base64EncodedString() }
        return try await request(path: "/v1/atlas", body: body)
    }

    func diagnose(image: UIImage?, symptom: String, speciesName: String = "", requirements: String = "") async throws -> PlantDiagnosis {
        var body: [String: Any] = ["symptom": symptom, "speciesName": speciesName, "requirements": requirements]
        if let image { body["image"] = try encodedImage(image) }
        return try await request(path: "/v1/diagnose", body: body)
    }

    private func imagePayload(_ image: UIImage) throws -> [String: Any] {
        ["image": try encodedImage(image)]
    }

    private func encodedImage(_ image: UIImage) throws -> String {
        // The Raspberry Pi runs the visual model on CPU. 384 px keeps the image
        // useful for genus recognition while avoiding multi-minute inference.
        let longestSide: CGFloat = 384
        let ratio = min(1, longestSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let scaled = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let data = scaled.jpegData(compressionQuality: 0.65), data.count <= 1_000_000 else {
            throw LocalPlantAIError.invalidImage
        }
        return data.base64EncodedString()
    }

    private func request<Response: Decodable>(path: String, body: [String: Any], method: String = "POST") async throws -> Response {
        let data = try JSONSerialization.data(withJSONObject: body)
        guard let baseURL = await reachableBaseURL() else { throw LocalPlantAIError.unavailable }
        do {
            var request = URLRequest(url: endpoint(path, on: baseURL))
            request.httpMethod = method
            request.timeoutInterval = 75
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = method == "GET" ? nil : data
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw LocalPlantAIError.unavailable }
            guard (200..<300).contains(http.statusCode) else {
                let message = (try? JSONDecoder().decode(ServerError.self, from: responseData).error) ?? "Serwer AI zwrócił błąd (\(http.statusCode))."
                throw LocalPlantAIError.server(message)
            }
            return try JSONDecoder().decode(Response.self, from: responseData)
        } catch {
            throw error
        }
    }

    private func reachableBaseURL() async -> URL? {
        for baseURL in baseURLs {
            do {
                var request = URLRequest(url: endpoint("health", on: baseURL))
                request.timeoutInterval = 3
                let (_, response) = try await URLSession.shared.data(for: request)
                if (response as? HTTPURLResponse)?.statusCode == 200 { return baseURL }
            } catch {
                continue
            }
        }
        return nil
    }

    private func endpoint(_ path: String, on baseURL: URL) -> URL {
        baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}

private struct ServerError: Decodable { let error: String }
