import Foundation

struct ApplicationContext {
    let bundleId: String
    let name: String
    let url: String?

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "bundleId": bundleId,
            "name": name
        ]
        if let url = url {
            dict["url"] = url
        }
        return dict
    }
}