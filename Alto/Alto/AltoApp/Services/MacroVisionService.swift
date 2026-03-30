import Foundation

protocol MacroVisionService {
    func analyzeMeal(imageData: Data) async throws -> MacroEstimate
}

enum MacroVisionError: Error {
    case missingAPIKey
    case badResponse
}

final class OpenAIVisionMacroService: MacroVisionService {
    private struct VisionResponse: Decodable {
        let output: [OutputItem]

        struct OutputItem: Decodable {
            let content: [Content]
        }

        struct Content: Decodable {
            let text: String?
        }
    }

    func analyzeMeal(imageData: Data) async throws -> MacroEstimate {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            throw MacroVisionError.missingAPIKey
        }

        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw MacroVisionError.badResponse
        }

        let base64 = imageData.base64EncodedString()
        let prompt = "Estimate meal macros from this image. Return strict JSON with keys calories (int), proteinGrams (number), carbsGrams (number), fatGrams (number)."

        let body: [String: Any] = [
            "model": "gpt-4.1-mini",
            "input": [[
                "role": "user",
                "content": [
                    ["type": "input_text", "text": prompt],
                    ["type": "input_image", "image_base64": base64]
                ]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw MacroVisionError.badResponse
        }

        let decoded = try JSONDecoder().decode(VisionResponse.self, from: data)
        guard let textPayload = decoded.output.first?.content.first?.text,
              let textData = textPayload.data(using: .utf8),
              let estimate = try? JSONDecoder().decode(MacroEstimate.self, from: textData) else {
            throw MacroVisionError.badResponse
        }

        return estimate
    }
}
