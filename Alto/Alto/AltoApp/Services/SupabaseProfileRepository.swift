import Foundation

final class SupabaseProfileRepository: ProfileRepository {
    func saveProfile(_ profile: UserProfileRecord) async throws {
        guard let baseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
            throw ProfileRepositoryError.missingConfiguration
        }
        guard let url = URL(string: "\(baseURL)/rest/v1/user_profiles") else {
            throw ProfileRepositoryError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        if let accessToken = ProcessInfo.processInfo.environment["SUPABASE_ACCESS_TOKEN"] {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(profile)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown Supabase error"
            throw ProfileRepositoryError.requestFailed(statusCode: http.statusCode, message: message)
        }
    }
}
