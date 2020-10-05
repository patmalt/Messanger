import Foundation

extension Data {
    var hex: String { map { String(format: "%02hhx", $0) }.joined() }
}
