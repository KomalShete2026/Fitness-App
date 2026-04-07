import Foundation

protocol VoiceWorkoutParsing {
    func parse(_ transcript: String) -> VoiceWorkoutEntry?
}

final class VoiceWorkoutParser: VoiceWorkoutParsing {
    func parse(_ transcript: String) -> VoiceWorkoutEntry? {
        let normalized = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let pattern = #"(?i)(?:i\s+did\s+)?(\d{1,3})\s*(?:min|mins|minutes)\s*(?:of)?\s*([a-zA-Z\s]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: normalized.utf16.count)
        guard let match = regex.firstMatch(in: normalized, options: [], range: range),
              match.numberOfRanges >= 3,
              let durationRange = Range(match.range(at: 1), in: normalized),
              let typeRange = Range(match.range(at: 2), in: normalized),
              let duration = Int(normalized[durationRange]) else {
            return nil
        }

        let rawType = String(normalized[typeRange])
        let cleanedType = rawType
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")

        guard !cleanedType.isEmpty else { return nil }

        return VoiceWorkoutEntry(
            workoutType: cleanedType.capitalized,
            durationMinutes: duration,
            sourceText: normalized,
            loggedAt: Date()
        )
    }
}
