import Foundation
import UIKit

@MainActor
enum AppEndpoints {
    static let registrationEndpoint = "https://api.pinlabelloupe.site/api/v1/users/register"
    static let networkTimeout: TimeInterval = 10

    static var defaultUserAgent: String {
        let version = UIDevice.current.systemVersion
        let token = version.replacingOccurrences(of: ".", with: "_")
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(token) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(version) Mobile/15E148 Safari/604.1"
    }
}
