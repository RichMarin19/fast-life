import Combine
import Foundation

protocol ContentOptOutManaging: AnyObject {
    var optedOutContentItems: [ContentItem] { get set }
    var objectWillChange: ObservableObjectPublisher { get }

    func isContentOptedOut(id: String) -> Bool
    func optOutContent(id: String, category: ContentCategory, text: String)
    func optInContent(id: String)
}

extension ContentOptOutManager: ContentOptOutManaging {}
