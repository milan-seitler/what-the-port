import Foundation

struct ServerInfo: Identifiable, Hashable {
    let id: String
    let port: Int
    let pid: Int32
    let command: String
    var title: String
    var statusCode: Int?
    var contentType: String?
    var bodyPreview: String?
    var lastChecked: Date

    var localURL: URL {
        URL(string: "http://127.0.0.1:\(port)")!
    }

    var displayName: String {
        if !title.isEmpty {
            return title
        }
        return command
    }
}
