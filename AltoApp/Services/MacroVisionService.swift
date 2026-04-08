import Foundation
import UIKit

protocol MacroVisionService {
    func analyzeMeal(imageData: Data) async throws -> MacroEstimate
}

enum MacroVisionError: Error, LocalizedError {
    case missingAPIKey
    case imageConversionFailed
    case invalidURL
    case apiError(statusCode: Int, message: String)
    case noResponseText
    case jsonParsingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key is missing. Please add it in Profile → Settings."
        case .imageConversionFailed:
            return "Failed to process image."
        case .invalidURL:
            return "Invalid API configuration."
        case .apiError(let statusCode, let message):
            if statusCode == 429 {
                return "Rate limit exceeded. Please wait a moment and try again."
            }
            return "API Error (\(statusCode)): \(message)"
        case .noResponseText:
            return "No response from AI service."
        case .jsonParsingFailed:
            return "Failed to analyze meal. Please try a clearer photo."
        }
    }
}

final class GeminiVisionMacroService: MacroVisionService {

    private let apiKey: String
    private let model: GeminiModel

    init(apiKey: String, model: GeminiModel = .flash15) {
        self.apiKey = apiKey
        self.model = model
    }

    func analyzeMeal(imageData: Data) async throws -> MacroEstimate {
        guard !apiKey.isEmpty else {
            throw MacroVisionError.missingAPIKey
        }

        let base64Image = imageData.base64EncodedString()
        let prompt = """
        Analyze this food photo and provide detailed nutritional information in JSON format.

        Respond with ONLY a valid JSON object in this exact format (no markdown, no explanation):
        {
            "calories": <integer>,
            "proteinGrams": <number>,
            "carbsGrams": <number>,
            "fatGrams": <number>
        }

        Guidelines:
        - Be realistic with portion sizes
        - Round calories to nearest 10
        - Round macros to 1 decimal place
        - If uncertain, provide conservative estimates
        """

        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": [
                        "mime_type": "image/jpeg",
                        "data": base64Image
                    ]]
                ]
            ]],
            "generationConfig": [
                "temperature": 0.4,
                "maxOutputTokens": 256,
                "responseMimeType": "application/json"
            ]
        ]

        guard let url = URL(string: "\(model.apiEndpoint)?key=\(apiKey)") else {
            throw MacroVisionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MacroVisionError.apiError(statusCode: 0, message: "Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MacroVisionError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw MacroVisionError.noResponseText
        }

        return try parseMacroEstimate(from: text)
    }

    private func parseMacroEstimate(from text: String) throws -> MacroEstimate {
        let cleanedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw MacroVisionError.jsonParsingFailed
        }

        do {
            return try JSONDecoder().decode(MacroEstimate.self, from: jsonData)
        } catch {
            throw MacroVisionError.jsonParsingFailed
        }
    }
}

// MARK: - Gemini API Response Models

private struct GeminiResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: Content

        struct Content: Codable {
            let parts: [Part]

            struct Part: Codable {
                let text: String?
            }
        }
    }
}

// MARK: - Backward Compatibility Alias

typealias OpenAIVisionMacroService = GeminiVisionMacroService
