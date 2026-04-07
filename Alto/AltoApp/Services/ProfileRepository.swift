import Foundation

protocol ProfileRepository {
    func saveProfile(_ profile: UserProfileRecord) async throws
}

enum ProfileRepositoryError: Error {
    case missingConfiguration
    case invalidURL
    case requestFailed(statusCode: Int, message: String)
}
