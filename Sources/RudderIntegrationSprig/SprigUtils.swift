import Foundation
import RudderStackAnalytics

enum SprigUtils {
    static let emailKey = "email"

    /// Maximum length (in characters) accepted by Sprig for a visitor-attribute key.
    /// Keys longer than this are trimmed to fit.
    static let maxAttributeKeyLength = 255

    /// Trait keys handled by dedicated Sprig setters (e.g. `setEmailAddress`) rather than the
    /// generic `setVisitorAttributes`. Keys listed here are skipped by the custom-trait loop so
    /// they are not also sent as visitor attributes.
    static let standardTraitKeys: Set<String> = [emailKey]

    static func filterTraits(_ traits: [String: Any]) -> [String: Any] {
        var filtered = [String: Any]()

        for (key, value) in traits {
            if standardTraitKeys.contains(key) {
                continue
            }
            if key.hasPrefix("!") {
                LoggerAnalytics.warn("SprigIntegration: '\(key)' is not a valid property name. Property names cannot start with '!'. Ignoring property.")
                continue
            }
            let normalizedKey = normalizeKeyLength(key)
            if value is String || value is Bool || value is Double || value is Int || value is NSNumber {
                filtered[normalizedKey] = value
            } else {
                LoggerAnalytics.warn("SprigIntegration: '\(value)' is not a valid property value. Only String, Bool, Double and Int are accepted. Ignoring property.")
            }
        }

        return filtered
    }

    private static func normalizeKeyLength(_ key: String) -> String {
        guard key.count > maxAttributeKeyLength else { return key }
        let trimmed = String(key.prefix(maxAttributeKeyLength))
        LoggerAnalytics.warn("SprigIntegration: property name '\(key)' exceeds \(maxAttributeKeyLength) characters. Trimming to '\(trimmed)'.")
        return trimmed
    }
}
