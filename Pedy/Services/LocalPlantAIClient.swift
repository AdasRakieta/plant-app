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
        URL(string: "http://192.168.1.218:8788")!,
        URL(string: "http://malina.tail384b18.ts.net:8788")!
    ]

    func identify(image: UIImage) async throws -> PlantIdentification {
        let body = try imagePayload(image)
        return try await request(path: "/v1/identify", body: body)
    }

    func diagnose(image: UIImage?, symptom: String, speciesName: String = "") async throws -> PlantDiagnosis {
        var body: [String: Any] = ["symptom": symptom, "speciesName": speciesName]
        if let image { body["image"] = try encodedImage(image) }
        return try await request(path: "/v1/diagnose", body: body)
    }

    private func imagePayload(_ image: UIImage) throws -> [String: Any] {
        ["image": try encodedImage(image)]
    }

    private func encodedImage(_ image: UIImage) throws -> String {
        let longestSide: CGFloat = 1_600
        let ratio = min(1, longestSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: size)
        let scaled = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let data = scaled.jpegData(compressionQuality: 0.78), data.count <= 8_000_000 else {
            throw LocalPlantAIError.invalidImage
        }
        return data.base64EncodedString()
    }

    private func request<Response: Decodable>(path: String, body: [String: Any]) async throws -> Response {
        let data = try JSONSerialization.data(withJSONObject: body)
        var lastError: Error = LocalPlantAIError.unavailable
        for baseURL in baseURLs {
            do {
                var request = URLRequest(url: baseURL.appending(path: path))
                request.httpMethod = "POST"
                request.timeoutInterval = 75
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = data
                let (responseData, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw LocalPlantAIError.unavailable }
                guard (200..<300).contains(http.statusCode) else {
                    let message = (try? JSONDecoder().decode(ServerError.self, from: responseData).error) ?? "Serwer AI zwrócił błąd (\(http.statusCode))."
                    throw LocalPlantAIError.server(message)
                }
                return try JSONDecoder().decode(Response.self, from: responseData)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}

private struct ServerError: Decodable { let error: String }
