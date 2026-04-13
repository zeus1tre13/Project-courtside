import Foundation

enum GeminiConfig {
    /// Gemini API key for roster scan fallback.
    /// Set this to your key, or load from environment/keychain in production.
    static let apiKey: String = {
        // Check UserDefaults first (can be set in Settings)
        if let key = UserDefaults.standard.string(forKey: "gemini_api_key"), !key.isEmpty {
            return key
        }
        // Hardcoded fallback for development — replace with your key
        return ""
    }()
}
