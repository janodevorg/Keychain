import Foundation

public enum KeychainError: Error, CustomStringConvertible, CustomDebugStringConvertible
{
    case unexpectedStatus(OSStatus, _ description: String?)

    var localizedString: String {
        switch self {
        case let KeychainError.unexpectedStatus(status, desc):
            return ["\(status)", desc].compactMap { $0 }.joined(separator: " ")
        }
    }
    public var description: String {
        localizedString
    }
    public var debugDescription: String {
        localizedString
    }
}
