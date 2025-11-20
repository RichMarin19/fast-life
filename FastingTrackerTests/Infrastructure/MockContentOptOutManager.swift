import Combine
@testable import FastLIFe

@MainActor
final class MockContentOptOutManager: ContentOptOutManaging {
    var optedOutContentItems: [ContentItem] = [] {
        didSet { objectWillChange.send() }
    }

    let objectWillChange = ObservableObjectPublisher()

    var isContentOptedOutHandler: ((String) -> Bool)?
    var optOutContentHandler: ((String, ContentCategory, String) -> Void)?
    var optInContentHandler: ((String) -> Void)?

    func isContentOptedOut(id: String) -> Bool {
        if let handler = isContentOptedOutHandler {
            return handler(id)
        }
        return optedOutContentItems.contains(where: { $0.id == id })
    }

    func optOutContent(id: String, category: ContentCategory, text: String) {
        if let handler = optOutContentHandler {
            handler(id, category, text)
            return
        }

        guard !optedOutContentItems.contains(where: { $0.id == id }) else { return }
        let item = ContentItem(id: id, category: category, displayText: text)
        optedOutContentItems.append(item)
    }

    func optInContent(id: String) {
        if let handler = optInContentHandler {
            handler(id)
            return
        }

        optedOutContentItems.removeAll { $0.id == id }
    }
}
