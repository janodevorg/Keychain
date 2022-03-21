import Foundation

enum KeychainType {

    /// Stores a piece of data tied to an account and access group.
    case genericPassword(account: String, accessGroup: String)

    /// Stores a piece of data tied to an account and service.
    case internetPassword(account: String, service: String)
}
