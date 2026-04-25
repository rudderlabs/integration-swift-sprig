import Foundation
import UIKit
import RudderStackAnalytics

public class SprigIntegration: IntegrationPlugin, StandardIntegration {

    public var pluginType: PluginType = .terminal
    public var analytics: Analytics?
    public var key: String = "Sprig"

    final let adapter: SprigAdapter
    private weak var viewController: UIViewController?
    private var loggingListenerRegistered = false

    init(adapter: SprigAdapter) {
        self.adapter = adapter
    }

    public convenience init() {
        self.init(adapter: DefaultSprigAdapter())
    }

    // MARK: - Public API

    /// Sets the view controller Sprig will present in-app surveys from.
    ///
    /// ## When to call
    /// Set the view controller when it becomes the active presentation context — typically from
    /// `viewDidAppear(_:)` of the topmost view controller in your app. You can clear it explicitly
    /// from `viewWillDisappear(_:)` by passing `nil`, but this is optional (see "Lifetime" below).
    ///
    /// ## Lifetime
    /// The reference is held **weakly**, so the integration will never keep your view controller
    /// alive past its natural lifetime. When the host releases its own reference, the stored
    /// reference auto-clears and subsequent `track` calls fall back to plain `Sprig.track(...)`
    /// (i.e. no survey is presented).
    ///
    /// ## Presentation safety
    /// On every `track` event, the integration:
    /// 1. Hops to the main thread (so it is safe to call `track` from any thread).
    /// 2. Verifies the stored view controller is still presentable — loaded, attached to a window,
    ///    and not being dismissed.
    /// 3. Falls back to plain `Sprig.track(...)` if the view controller has gone away or is no
    ///    longer in a presentable state. No exception is thrown; the event is still delivered.
    ///
    /// - Parameter viewController: The view controller to present surveys from, or `nil` to clear.
    public func setViewController(_ viewController: UIViewController?) {
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
        registerSprigLogging()
        LoggerAnalytics.debug("SprigIntegration: Sprig SDK initialized successfully.")
    }

    public func reset() {
        adapter.logout()
        LoggerAnalytics.debug("SprigIntegration: Sprig logout called.")
    }

    public func teardown() {
        if loggingListenerRegistered {
            adapter.unregisterLoggingListener()
            loggingListenerRegistered = false
        }
        LoggerAnalytics.debug("SprigIntegration: teardown completed.")
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
        let eventName = payload.event
        let properties = payload.properties?.dictionary?.rawDictionary

        runOnMain { [weak self] in
            guard let self = self else { return }

            if let viewController = self.viewController, Self.isPresentable(viewController) {
                self.adapter.trackAndPresent(eventName: eventName, properties: properties, from: viewController)
                LoggerAnalytics.debug("SprigIntegration: trackAndPresent called for event '\(eventName)'")
            } else {
                self.adapter.track(eventName: eventName, properties: properties)
                LoggerAnalytics.debug("SprigIntegration: track called for event '\(eventName)'")
            }
        }
    }

    // MARK: - Helpers

    /// Forwards Sprig SDK log messages to the Rudder logger.
    ///
    /// Sprig iOS emits log output via `.loggingEvent` lifecycle callbacks but — unlike Sprig
    /// Android — does not expose a severity with each message, so every message is forwarded
    /// at `debug`. Registration is skipped when the Rudder log level is `.none`, and guarded
    /// so repeated `create(...)` calls do not stack listeners.
    private func registerSprigLogging() {
        guard !loggingListenerRegistered else { return }
        guard LoggerAnalytics.logLevel != .none else { return }

        adapter.registerLoggingListener { message in
            LoggerAnalytics.debug("SprigIntegration: \(message)")
        }
        loggingListenerRegistered = true
    }

    private func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    private static func isPresentable(_ viewController: UIViewController) -> Bool {
        return viewController.isViewLoaded
            && viewController.view.window != nil
            && !viewController.isBeingDismissed
    }
}
