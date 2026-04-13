import Foundation
import Vision
import UIKit

struct ScannedPlayer {
    let jerseyNumber: String
    let firstName: String
    let lastName: String
}

enum ScanResult {
    case success([ScannedPlayer])
    case needsFallback(UIImage) // Vision couldn't parse, try Gemini
    case failure(String)
}

actor RosterScanner {

    // MARK: - Vision OCR (on-device)

    func scanWithVision(image: UIImage) async -> ScanResult {
        guard let cgImage = image.cgImage else {
            return .failure("Could not process image")
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return .failure("Vision OCR failed: \(error.localizedDescription)")
        }

        guard let observations = request.results, !observations.isEmpty else {
            return .needsFallback(image)
        }

        // Collect all recognized text lines
        let lines = observations.compactMap { observation -> String? in
            observation.topCandidates(1).first?.string
        }

        // Try to parse roster entries
        let players = parseRosterLines(lines)

        if players.isEmpty {
            return .needsFallback(image)
        }

        return .success(players)
    }

    // MARK: - Parse Lines

    /// Tries to extract jersey number + name from recognized text lines.
    /// Handles common formats:
    ///   "23 Tatum Odell"
    ///   "#23 Tatum Odell"
    ///   "23 - Odell, Tatum"
    ///   "Odell, Tatum  23"
    private func parseRosterLines(_ lines: [String]) -> [ScannedPlayer] {
        var players: [ScannedPlayer] = []

        for line in lines {
            if let player = parseRosterLine(line) {
                players.append(player)
            }
        }

        return players
    }

    private func parseRosterLine(_ line: String) -> ScannedPlayer? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Pattern 1: #NUMBER NAME or NUMBER NAME (number first)
        // e.g., "#23 Tatum Odell", "23 Tatum Odell", "23 - Tatum Odell"
        let numberFirstPattern = #/^#?(\d{1,3})\s*[-–—.]?\s+(.+)$/#
        if let match = trimmed.firstMatch(of: numberFirstPattern) {
            let number = String(match.1)
            let namePart = String(match.2).trimmingCharacters(in: .whitespaces)
            if let (first, last) = parseName(namePart) {
                return ScannedPlayer(jerseyNumber: number, firstName: first, lastName: last)
            }
        }

        // Pattern 2: NAME NUMBER (number last)
        // e.g., "Odell, Tatum 23", "Tatum Odell 23"
        let numberLastPattern = #/^(.+?)\s+#?(\d{1,3})$/#
        if let match = trimmed.firstMatch(of: numberLastPattern) {
            let namePart = String(match.1).trimmingCharacters(in: .whitespaces)
            let number = String(match.2)
            if let (first, last) = parseName(namePart) {
                return ScannedPlayer(jerseyNumber: number, firstName: first, lastName: last)
            }
        }

        return nil
    }

    /// Parses "First Last" or "Last, First" format
    private func parseName(_ raw: String) -> (first: String, last: String)? {
        let cleaned = raw
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))

        guard !cleaned.isEmpty else { return nil }

        // "Last, First" format
        if cleaned.contains(",") {
            let parts = cleaned.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            if parts.count >= 2 {
                return (first: parts[1], last: parts[0])
            }
            return (first: "", last: parts[0])
        }

        // "First Last" format
        let words = cleaned.split(separator: " ").map(String.init)
        if words.count >= 2 {
            let first = words[0]
            let last = words[1...].joined(separator: " ")
            return (first: first, last: last)
        }

        // Single name — treat as last name
        return (first: "", last: cleaned)
    }

    // MARK: - Gemini Fallback

    func scanWithGemini(image: UIImage, apiKey: String) async -> ScanResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return .failure("Could not compress image")
        }

        let base64Image = imageData.base64EncodedString()

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "text": """
                            Extract all basketball players from this roster/lineup image.
                            Return ONLY a JSON array with objects containing "number", "firstName", "lastName".
                            Example: [{"number": "23", "firstName": "Tatum", "lastName": "Odell"}]
                            If you cannot find any players, return an empty array: []
                            Return ONLY the JSON array, no other text.
                            """
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            return .failure("Invalid Gemini API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return .failure("Failed to create request: \(error.localizedDescription)")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .failure("Gemini API error")
            }

            // Parse Gemini response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                return .failure("Could not parse Gemini response")
            }

            // Extract JSON array from response text
            let players = parseGeminiResponse(text)
            if players.isEmpty {
                return .failure("No players found in image")
            }
            return .success(players)

        } catch {
            return .failure("Network error: \(error.localizedDescription)")
        }
    }

    private func parseGeminiResponse(_ text: String) -> [ScannedPlayer] {
        // Find JSON array in response (may have markdown backticks)
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }

        return array.compactMap { dict in
            guard let number = dict["number"],
                  let lastName = dict["lastName"] else { return nil }
            let firstName = dict["firstName"] ?? ""
            return ScannedPlayer(jerseyNumber: number, firstName: firstName, lastName: lastName)
        }
    }
}
