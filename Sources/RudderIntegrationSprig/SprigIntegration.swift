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
        // TODO: implement
        return nil
    }

    public func create(destinationConfig: [String: Any]) throws {
        // TODO: implement
    }

    public func reset() {
        // TODO: implement
    }

    // MARK: - EventPlugin

    public func identify(payload: IdentifyEvent) {
        // TODO: implement
    }

    public func track(payload: TrackEvent) {
        // TODO: implement
    }
}
