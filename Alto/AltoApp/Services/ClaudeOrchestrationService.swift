import Foundation

// MARK: - Response models (shared JSON schema)

private struct AIPlanResponse: Decodable {
    let headline: String
    let why: String
    let activities: [AIActivity]
    let calorieTarget: Int
    let readinessSummary: String
    let shouldPivot: Bool
    let pivotReason: String?
    let coachNote: String
}

private struct AIActivity: Decodable {
    let name: String
    let emoji: String
    let durationMinutes: Int
    let targetCalories: Int
    let details: String
    let location: String  // "indoor" | "outdoor"
    let rpe: Int
}

// MARK: - Gemini API response envelope

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
}
private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}
private struct GeminiContent: Decodable {
    let parts: [GeminiPart]
}
private struct GeminiPart: Decodable {
    let text: String
}

// MARK: - Errors

enum ClaudeOrchestrationError: LocalizedError {
    case missingAPIKey
    case networkError(Error)
    case invalidResponse(String)
    case jsonParseError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key is missing. Please add it in Profile → Settings."
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .invalidResponse(let detail):
            if detail.contains("429") {
                return "Rate limit exceeded. Please wait a moment and try again."
            }
            return "Invalid response from AI: \(detail)"
        case .jsonParseError(let detail):
            return "Failed to generate plan: \(detail)"
        }
    }
}

// MARK: - AI Orchestration Service (powered by Gemini)

/// Calls Gemini 1.5 Pro to generate a personalised daily training plan.
/// Public interface is identical to the previous Claude-backed version —
/// no other files need to change.
final class ClaudeOrchestrationService {

    private let apiKey: String
    private let model: GeminiModel

    private var apiURL: URL {
        URL(string: "\(model.apiEndpoint)?key=\(apiKey)")!
    }

    init(apiKey: String, model: GeminiModel = .pro15) {
        self.apiKey = apiKey
        self.model = model
    }

    // MARK: - Public API

    func buildPlanAsync(context: OrchestratorContext, userEnteredActivities: [UserEnteredActivity] = []) async throws -> OrchestratedPlan {
        let prompt = buildPrompt(context: context, userEnteredActivities: userEnteredActivities)
        let raw    = try await callGemini(systemPrompt: systemPrompt, userMessage: prompt)
        return try parsePlan(from: raw)
    }

    // MARK: - System prompt

    private var systemPrompt: String {
        """
        You are Alto's AI fitness coach. Generate a personalised daily training plan \
        based on the user's readiness signals, goals, environment, and any activities they've already planned.

        Rules:
        1. If readiness score < 40, always recommend a rest/recovery day regardless of what was planned.
        2. If rain probability > 60% and any activity is outdoor, swap it for an indoor equivalent.
        3. If the user is in their luteal cycle phase, cap RPE at 7 and reduce duration by 10%.
        4. Respect health conditions — never suggest high-impact activities for joint issues.
        5. If the user entered their own planned activities, honour them unless safety rules (1-4) override.
        6. If planned activities burn fewer calories than the calorie target, suggest one short add-on.
        7. Each activity description should be specific and motivating — not generic.
        8. Explain WHY you made the plan in 1-2 sentences in the "why" field.
        9. The coachNote should feel personal and warm — like a text from a coach who knows you.

        Respond ONLY with a single valid JSON object. No markdown, no explanation outside the JSON.

        JSON schema:
        {
          "headline": "string (max 40 chars, punchy)",
          "why": "string (1-2 sentences explaining the plan)",
          "activities": [
            {
              "name": "string",
              "emoji": "string (single emoji)",
              "durationMinutes": number,
              "targetCalories": number,
              "details": "string (specific instructions, max 80 chars)",
              "location": "indoor or outdoor",
              "rpe": number (1-10)
            }
          ],
          "calorieTarget": number,
          "readinessSummary": "string (1 sentence, e.g. Readiness 78/100 — body is primed)",
          "shouldPivot": boolean,
          "pivotReason": "string or null",
          "coachNote": "string (personal, warm, 1 sentence)"
        }
        """
    }

    // MARK: - Prompt construction

    private func buildPrompt(context: OrchestratorContext, userEnteredActivities: [UserEnteredActivity]) -> String {
        let readinessScore = computeReadinessScore(readiness: context.readiness, mood: context.mood)
        var sections: [String] = []

        sections.append("""
        USER PROFILE
        Goal: \(context.goalName)
        Training phase: \(context.goalPhase.rawValue)
        Activity level: \(context.activityPreset)
        Health conditions: \(context.healthConditions.isEmpty ? "None" : context.healthConditions.joined(separator: ", "))
        Workout preferences: \(context.workoutPreferences.isEmpty ? "Not specified" : context.workoutPreferences.joined(separator: ", "))
        """)

        let r = context.readiness
        sections.append("""
        TODAY'S SIGNALS
        Readiness score: \(readinessScore)/100
        Soreness (1=worst, 5=best): \(r?.soreness ?? 3)
        Stress (1=worst, 5=best): \(r?.stress ?? 3)
        Motivation (1=worst, 5=best): \(r?.mood ?? 3)
        Mood: \(context.mood.rawValue)
        Cycle phase: \(r?.cyclePhase.rawValue ?? "Unknown")
        """)

        var envLines = ["ENVIRONMENT"]
        if let sleep = context.sleepHours      { envLines.append("Sleep last night: \(String(format: "%.1f", sleep))h") }
        if let rain  = context.rainProbability { envLines.append("Rain probability: \(Int(rain * 100))%") }
        if let temp  = context.temperatureCelsius { envLines.append("Temperature: \(Int(temp))°C") }
        envLines.append("Weather: \(weatherDescription(context.weatherImpact))")
        sections.append(envLines.joined(separator: "\n"))

        sections.append("CALORIE BURN TARGET TODAY: \(context.calorieTarget) kcal")

        if !userEnteredActivities.isEmpty {
            let lines = userEnteredActivities.map { "- \($0.name) (\($0.duration))" }
            sections.append("USER'S PLANNED ACTIVITIES (honour unless safety rules override):\n\(lines.joined(separator: "\n"))")
        } else {
            sections.append("USER'S PLANNED ACTIVITIES: Not entered — decide based on phase and readiness.")
        }

        sections.append("Generate the daily plan now.")
        return sections.joined(separator: "\n\n")
    }

    private func computeReadinessScore(readiness: DailyReadiness?, mood: DailyMood) -> Int {
        guard let r = readiness else { return 65 }
        var score = 100
        if r.soreness < 3 { score -= 30 }
        if r.stress   < 3 { score -= 20 }
        if r.mood     < 3 { score -= 20 } else if r.mood == 3 { score -= 10 }
        if r.cyclePhase == .luteal { score -= 10 }
        return max(0, min(100, score))
    }

    private func weatherDescription(_ impact: WeatherImpact) -> String {
        switch impact {
        case .clear:   return "Clear"
        case .rain:    return "Rainy"
        case .extreme: return "Extreme — indoor only"
        }
    }

    // MARK: - Gemini API call

    private func callGemini(systemPrompt: String, userMessage: String) async throws -> String {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Gemini uses systemInstruction + user contents
        let body: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                ["role": "user", "parts": [["text": userMessage]]]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 1024,
                "responseMimeType": "application/json"  // forces JSON output
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ClaudeOrchestrationError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeOrchestrationError.invalidResponse("Non-HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "empty"
            throw ClaudeOrchestrationError.invalidResponse("HTTP \(http.statusCode): \(body)")
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates.first?.content.parts.first?.text else {
            throw ClaudeOrchestrationError.invalidResponse("No text in Gemini response")
        }
        return text
    }

    // MARK: - Response parsing

    private func parsePlan(from text: String) throws -> OrchestratedPlan {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw ClaudeOrchestrationError.jsonParseError("Could not encode response as UTF-8")
        }

        let plan: AIPlanResponse
        do {
            plan = try JSONDecoder().decode(AIPlanResponse.self, from: jsonData)
        } catch {
            throw ClaudeOrchestrationError.jsonParseError(error.localizedDescription)
        }

        let actions = plan.activities.map { act in
            OrchestratedAction(
                title: act.name,
                details: "\(act.durationMinutes) min · RPE \(act.rpe) · \(act.details)"
            )
        }

        let plannedActivities = plan.activities.map { act in
            PlannedActivity(
                name: act.name,
                emoji: act.emoji,
                durationMinutes: act.durationMinutes,
                targetCalories: Double(act.targetCalories),
                details: act.details
            )
        }

        return OrchestratedPlan(
            headline: plan.headline,
            why: plan.why,
            workoutName: plan.activities.first?.name ?? "Rest",
            workoutDurationMinutes: plan.activities.first?.durationMinutes ?? 0,
            actions: actions,
            shouldPivot: plan.shouldPivot,
            plannedActivities: plannedActivities,
            calorieTarget: plan.calorieTarget,
            readinessSummary: plan.readinessSummary,
            coachNote: plan.coachNote,
            pivotReason: plan.pivotReason
        )
    }
}

// MARK: - Supporting types

struct UserEnteredActivity {
    let name: String
    let duration: String
}
