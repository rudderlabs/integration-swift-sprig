import UIKit
@testable import RudderIntegrationSprig

class MockSprigAdapter: SprigAdapter {
    var configureCalls: [String] = []
    var setUserIdentifierCalls: [String] = []
    var setEmailAddressCalls: [String] = []
    var setVisitorAttributesCalls: [[String: Any]] = []
    var trackCalls: [(eventName: String, properties: [String: Any]?)] = []
    var trackAndPresentCalls: [(eventName: String, properties: [String: Any]?, viewController: UIViewController)] = []
    var lastTrackOnMainThread: Bool?
    var lastTrackAndPresentOnMainThread: Bool?
    var logoutCalled = false

    var onTrack: (() -> Void)?
    var onTrackAndPresent: (() -> Void)?

    func configure(withEnvironment environmentId: String) {
        configureCalls.append(environmentId)
    }

    func setUserIdentifier(_ userId: String) {
        setUserIdentifierCalls.append(userId)
    }

    func setEmailAddress(_ email: String) {
        setEmailAddressCalls.append(email)
    }

    func setVisitorAttributes(_ attributes: [String: Any]) {
        setVisitorAttributesCalls.append(attributes)
    }

    func track(eventName: String, properties: [String: Any]?) {
        lastTrackOnMainThread = Thread.isMainThread
        trackCalls.append((eventName: eventName, properties: properties))
        onTrack?()
    }

    func trackAndPresent(eventName: String, properties: [String: Any]?, from viewController: UIViewController) {
        lastTrackAndPresentOnMainThread = Thread.isMainThread
        trackAndPresentCalls.append((eventName: eventName, properties: properties, viewController: viewController))
        onTrackAndPresent?()
    }

    func logout() {
        logoutCalled = true
    }

    func getSprigInstance() -> Any? {
        return "MockSprigInstance"
    }
}
