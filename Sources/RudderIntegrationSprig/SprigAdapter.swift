import Foundation
import UserLeapKit

protocol SprigAdapter {
    func configure(withEnvironment environmentId: String)
    func setUserIdentifier(_ userId: String)
    func setEmailAddress(_ email: String)
    func setVisitorAttributes(_ attributes: [String: Any])
    func track(eventName: String, properties: [String: Any]?)
    func trackAndPresent(eventName: String, properties: [String: Any]?, from viewController: UIViewController)
    func logout()
    func getSprigInstance() -> Any?
}

class DefaultSprigAdapter: SprigAdapter {
    func configure(withEnvironment environmentId: String) {
        Sprig.shared.configure(withEnvironment: environmentId)
    }

    func setUserIdentifier(_ userId: String) {
        Sprig.shared.setUserIdentifier(userId)
    }

    func setEmailAddress(_ email: String) {
        Sprig.shared.setEmailAddress(email)
    }

    func setVisitorAttributes(_ attributes: [String: Any]) {
        Sprig.shared.setVisitorAttributes(attributes)
    }

    func track(eventName: String, properties: [String: Any]?) {
        let payload = EventPayload(eventName: eventName, properties: properties)
        Sprig.shared.track(payload: payload)
    }

    func trackAndPresent(eventName: String, properties: [String: Any]?, from viewController: UIViewController) {
        let payload = EventPayload(eventName: eventName, properties: properties)
        Sprig.shared.trackAndPresent(payload: payload, from: viewController)
    }

    func logout() {
        Sprig.shared.logout()
    }

    func getSprigInstance() -> Any? {
        return Sprig.shared
    }
}
