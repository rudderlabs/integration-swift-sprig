import Foundation
import UserLeapKit
import RudderStackAnalytics

public class SprigIntegration: IntegrationPlugin, StandardIntegration {

    public var pluginType: PluginType = .terminal
    public var analytics: Analytics?
    public var key: String = "Sprig"

    final let adapter: SprigAdapter
    private var viewController: UIViewController?

    init(adapter: SprigAdapter) {
        self.adapter = adapter
    }

    public convenience init() {
        self.init(adapter: DefaultSprigAdapter())
    }

    // MARK: - Public API

    public func setViewController(_ viewController: UIViewController) {
        self.viewController = viewController
    }

    // MARK: - IntegrationPlugin

    public func getDestinationInstance() -> Any? {
        return adapter.getSprigInstance()
    }

    public func create(destinationConfig: [String: Any]) throws {
        guard let environmentId = destinationConfig["environmentId"] as? String, !environmentId.isEmpty else {
            LoggerAnalytics.error("SprigIntegration: Invalid or missing environmentId. Aborting Sprig initialization.")
            return
        }
        adapter.configure(withEnvironment: environmentId)
        LoggerAnalytics.debug("SprigIntegration: Sprig SDK initialized successfully.")
    }

    public func reset() {
        // TODO: implement
    }

    // MARK: - EventPlugin

    public func identify(payload: IdentifyEvent) {
        guard let userId = payload.userId, !userId.isEmpty else {
            LoggerAnalytics.error("SprigIntegration: UserId is not set. Dropping identify event.")
            return
        }
        adapter.setUserIdentifier(userId)

        if let traits = payload.context?["traits"] as? AnyCodable,
           let traitsDictionary = traits.value as? [String: Any] {
            if let email = traitsDictionary["email"] as? String {
                adapter.setEmailAddress(email)
            }
            let filteredTraits = SprigUtils.filterTraits(traitsDictionary)
            if !filteredTraits.isEmpty {
                adapter.setVisitorAttributes(filteredTraits)
            }
        }

        LoggerAnalytics.debug("SprigIntegration: Identify event processed for userId: \(userId)")
    }

    public func track(payload: TrackEvent) {
        // TODO: implement
    }
}
