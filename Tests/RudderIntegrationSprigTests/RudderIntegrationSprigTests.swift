import Testing
import Foundation
import RudderStackAnalytics
@testable import RudderIntegrationSprig

@Suite("RudderIntegrationSprig Tests")
struct SprigIntegrationTests {

    // MARK: - Test Setup Helpers

    private func createIntegration(mockAdapter: MockSprigAdapter = MockSprigAdapter()) -> (SprigIntegration, MockSprigAdapter) {
        let integration = SprigIntegration(adapter: mockAdapter)
        return (integration, mockAdapter)
    }

    private func createIdentifyEvent(userId: String? = nil, traits: [String: Any]? = nil) -> IdentifyEvent {
        var event = IdentifyEvent()
        event.userId = userId
        if let traits = traits {
            event.context = (event.context ?? [:]).merging(["traits": AnyCodable(traits)]) { _, new in new }
        }
        return event
    }

    private func createTrackEvent(name: String, properties: [String: Any]? = nil) -> TrackEvent {
        return TrackEvent(event: name, properties: properties)
    }

    // MARK: - Initialization Tests

    @Test("Given SprigIntegration, when initialized, then has correct default properties")
    func testDefaultInitialization() {
        let integration = SprigIntegration()

        #expect(integration.key == "Sprig")
        #expect(integration.pluginType == .terminal)
        #expect(integration.analytics == nil)
    }

    // MARK: - Create Tests

    @Test("Given valid environmentId, when create is called, then configures Sprig SDK")
    func testCreateWithValidConfig() throws {
        let (integration, mock) = createIntegration()

        try integration.create(destinationConfig: ["environmentId": "test-env-123"])

        #expect(mock.configureCalls.count == 1)
        #expect(mock.configureCalls.first == "test-env-123")
    }

    @Test("Given missing environmentId, when create is called, then does not configure Sprig SDK")
    func testCreateWithMissingConfig() throws {
        let (integration, mock) = createIntegration()

        try integration.create(destinationConfig: [:])

        #expect(mock.configureCalls.isEmpty)
    }

    @Test("Given empty environmentId, when create is called, then does not configure Sprig SDK")
    func testCreateWithEmptyEnvironmentId() throws {
        let (integration, mock) = createIntegration()

        try integration.create(destinationConfig: ["environmentId": ""])

        #expect(mock.configureCalls.isEmpty)
    }

    // MARK: - GetDestinationInstance Tests

    @Test("Given SprigIntegration, when getDestinationInstance is called, then returns adapter instance")
    func testGetDestinationInstance() {
        let (integration, _) = createIntegration()

        let instance = integration.getDestinationInstance()

        #expect(instance as? String == "MockSprigInstance")
    }

    // MARK: - Identify Tests

    @Test("Given valid userId, when identify is called, then sets user identifier")
    func testIdentifyWithUserId() {
        let (integration, mock) = createIntegration()
        let event = createIdentifyEvent(userId: "user-123")

        integration.identify(payload: event)

        #expect(mock.setUserIdentifierCalls.count == 1)
        #expect(mock.setUserIdentifierCalls.first == "user-123")
    }

    @Test("Given nil userId, when identify is called, then drops event")
    func testIdentifyWithNilUserId() {
        let (integration, mock) = createIntegration()
        let event = createIdentifyEvent(userId: nil)

        integration.identify(payload: event)

        #expect(mock.setUserIdentifierCalls.isEmpty)
    }

    @Test("Given empty userId, when identify is called, then drops event")
    func testIdentifyWithEmptyUserId() {
        let (integration, mock) = createIntegration()
        let event = createIdentifyEvent(userId: "")

        integration.identify(payload: event)

        #expect(mock.setUserIdentifierCalls.isEmpty)
    }

    @Test("Given traits with email, when identify is called, then sets email address")
    func testIdentifyWithEmail() {
        let (integration, mock) = createIntegration()
        let event = createIdentifyEvent(userId: "user-123", traits: ["email": "test@example.com", "name": "Test"])

        integration.identify(payload: event)

        #expect(mock.setEmailAddressCalls.count == 1)
        #expect(mock.setEmailAddressCalls.first == "test@example.com")
    }

    @Test("Given traits with valid attributes, when identify is called, then sets visitor attributes without email")
    func testIdentifyFiltersEmailFromAttributes() {
        let (integration, mock) = createIntegration()
        let event = createIdentifyEvent(userId: "user-123", traits: ["email": "test@example.com", "name": "Test", "age": 30])

        integration.identify(payload: event)

        #expect(mock.setVisitorAttributesCalls.count == 1)
        let attributes = mock.setVisitorAttributesCalls.first!
        #expect(attributes["email"] == nil)
        #expect(attributes["name"] as? String == "Test")
        #expect(attributes["age"] as? Int == 30)
    }

    // MARK: - Track Tests

    @Test("Given track event, when no viewController set, then calls track")
    func testTrackWithoutViewController() {
        let (integration, mock) = createIntegration()
        let event = createTrackEvent(name: "Button Clicked", properties: ["buttonId": "cta-1"])

        integration.track(payload: event)

        #expect(mock.trackCalls.count == 1)
        #expect(mock.trackCalls.first?.eventName == "Button Clicked")
    }

    // MARK: - Reset Tests

    @Test("Given SprigIntegration, when reset is called, then calls logout")
    func testReset() {
        let (integration, mock) = createIntegration()

        integration.reset()

        #expect(mock.logoutCalled)
    }
}

// MARK: - SprigUtils Tests

@Suite("SprigUtils Tests")
struct SprigUtilsTests {

    @Test("Given traits with email, when filterTraits is called, then email is excluded")
    func testFilterTraitsExcludesEmail() {
        let traits: [String: Any] = ["email": "test@example.com", "name": "Test"]
        let filtered = SprigUtils.filterTraits(traits)

        #expect(filtered["email"] == nil)
        #expect(filtered["name"] as? String == "Test")
    }

    @Test("Given key starting with !, when filterTraits is called, then key is excluded")
    func testFilterTraitsExcludesExclamationPrefix() {
        let traits: [String: Any] = ["!internal": "value", "valid": "value"]
        let filtered = SprigUtils.filterTraits(traits)

        #expect(filtered["!internal"] == nil)
        #expect(filtered["valid"] as? String == "value")
    }

    @Test("Given key longer than 255 chars, when filterTraits is called, then key is excluded")
    func testFilterTraitsExcludesLongKeys() {
        let longKey = String(repeating: "a", count: 256)
        let traits: [String: Any] = [longKey: "value", "short": "value"]
        let filtered = SprigUtils.filterTraits(traits)

        #expect(filtered[longKey] == nil)
        #expect(filtered["short"] as? String == "value")
    }

    @Test("Given unsupported value type, when filterTraits is called, then value is excluded")
    func testFilterTraitsExcludesUnsupportedTypes() {
        let traits: [String: Any] = ["array": [1, 2, 3], "valid": "string"]
        let filtered = SprigUtils.filterTraits(traits)

        #expect(filtered["array"] == nil)
        #expect(filtered["valid"] as? String == "string")
    }

    @Test("Given supported value types, when filterTraits is called, then values are included")
    func testFilterTraitsIncludesSupportedTypes() {
        let traits: [String: Any] = [
            "stringVal": "hello",
            "boolVal": true,
            "doubleVal": 3.14,
            "intVal": 42
        ]
        let filtered = SprigUtils.filterTraits(traits)

        #expect(filtered.count == 4)
        #expect(filtered["stringVal"] as? String == "hello")
        #expect(filtered["boolVal"] as? Bool == true)
        #expect(filtered["doubleVal"] as? Double == 3.14)
        #expect(filtered["intVal"] as? Int == 42)
    }
}
