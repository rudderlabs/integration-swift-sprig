import Foundation
import UIKit
import RudderStackAnalytics

@objc(RSSSprigIntegration)
public class ObjCSprigIntegration: NSObject, ObjCIntegrationPlugin, ObjCStandardIntegration {

    // MARK: - ObjCPlugin Properties

    public var pluginType: PluginType {
        get { sprigIntegration.pluginType }
        set { sprigIntegration.pluginType = newValue }
    }

    // MARK: - ObjCIntegrationPlugin Properties

    public var key: String {
        get { sprigIntegration.key }
        set { sprigIntegration.key = newValue }
    }

    // MARK: - Private Properties

    private let sprigIntegration: SprigIntegration

    // MARK: - Initializers

    @objc
    public override init() {
        self.sprigIntegration = SprigIntegration()
        super.init()
    }

    // MARK: - Public API

    /// Sets the view controller used by Sprig to present in-app surveys.
    ///
    /// The reference is held weakly, so the integration will never keep your view controller alive.
    /// When the host releases its own reference, the integration automatically falls back to plain
    /// `track` for subsequent events. You may also pass `nil` to clear the reference explicitly.
    @objc
    public func setViewController(_ viewController: UIViewController?) {
        sprigIntegration.setViewController(viewController)
    }

    // MARK: - ObjCIntegrationPlugin Methods

    @objc
    public func getDestinationInstance() -> Any? {
        return sprigIntegration.getDestinationInstance()
    }

    @objc
    public func createWithDestinationConfig(_ destinationConfig: [String: Any], error errorPointer: NSErrorPointer) -> Bool {
        do {
            try sprigIntegration.create(destinationConfig: destinationConfig)
            return true
        } catch let err as NSError {
            errorPointer?.pointee = err
            return false
        } catch {
            errorPointer?.pointee = NSError(
                domain: "com.rudderstack.SprigIntegration",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
            )
            return false
        }
    }

    // MARK: - ObjCEventPlugin Methods

    @objc
    public func identify(_ payload: ObjCIdentifyEvent) {
        var identifyEvent = IdentifyEvent(options: payload.options)
        identifyEvent.anonymousId = payload.anonymousId
        identifyEvent.userId = payload.userId
        identifyEvent.context = payload.context?.codableWrapped

        sprigIntegration.identify(payload: identifyEvent)
    }

    @objc
    public func track(_ payload: ObjCTrackEvent) {
        var trackEvent = TrackEvent(
            event: payload.eventName,
            properties: payload.properties,
            options: payload.options
        )
        trackEvent.anonymousId = payload.anonymousId
        trackEvent.userId = payload.userId

        sprigIntegration.track(payload: trackEvent)
    }

    @objc
    public func reset() {
        sprigIntegration.reset()
    }
}
