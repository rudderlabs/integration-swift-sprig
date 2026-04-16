import Foundation
import RudderStackAnalytics

enum SprigUtils {
    static func filterTraits(_ traits: [String: Any]) -> [String: Any] {
        var filtered = [String: Any]()

        for (key, value) in traits {
            if key == "email" {
                continue
            }
            guard key.count < 256, !key.hasPrefix("!") else {
                LoggerAnalytics.warn("SprigIntegration: '\(key)' is not a valid property name. Property names must be less than 256 characters and cannot start with '!'. Ignoring property.")
                continue
            }
            if value is String || value is Bool || value is Double || value is Int {
                filtered[key] = value
            } else {
                LoggerAnalytics.warn("SprigIntegration: '\(value)' is not a valid property value. Only String, Bool, Double and Int are accepted. Ignoring property.")
            }
        }

        return filtered
    }
}
