# ``Keychain``

Keychain wrapper.

## Overview

### Enable keychain sharing

To enable keychain item sharing:

- Enable Keychain Sharing in target > Signing & Capabilities. Click the plus sign to add the capability Keychain Sharing.
- Set a value in "Keychain Groups" for your shared keychain items. The value must start with the
Bundle Seed ID, followed by an arbitrary string. A single keychain group can store multiple items.

This adds a file <TargetName>.entitlements, pointed by Build Settings > Code Signing
Entitlements, with something like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix).myapp.credentials</string>
    </array>
</dict>
</plist>
```

The `$(AppIdentifierPrefix)` expands to your Team ID, so the final string might look like `PPSF6CNP8Q.myapp.credentials`.
The Team ID is listed in the Member Center. You can store multiple keychain items (like API keys, tokens, passwords) within a single group. Each item in the group is identified by a unique key when you save it to the keychain.

![AppIdentifier](AppIdentifier)

Note: If you’re just storing items locally for a single app, you can omit a custom access group and skip this setup. But if you use an accessGroup, make sure your test targets also have matching entitlements.

### Usage 

Store a value as a generic password:
```swift
let account = "OpenAI-key" // or other arbitrary string
let accessGroup = "PPSF6CNP8Q.myapp.credentials"
let store = ValueKeychainStore(accountName: account, accessGroup: accessGroup)
store.set("sk-proj-78Bmxfp9zMCrOauFJXuX") // set the key
print(store.get()) // print the key
```

Use the `ObservedValueStore` to react to updates:
```swift
let accessGroup = "PPSF6CNP8Q.myapp.credentials"
let underlyingStore = ValueKeychainStore(accountName: account, accessGroup: accessGroup)
let store = await ObservedValueStore(valueStore: underlyingStore)
let observation = await store.observe { [weak self] value in
    print("Value changed to \(String(describing: newValue))")
} 
try await store.set("bananas")
observation.stopObserving()
```

![Keychain](Keychain)

## Security Best Practices

### Access Control

Specify an appropriate accessibility level:
```swift
let extraAttributes: [String: AnyObject] = [
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]
try store.create("secure-value", extraAttributes: extraAttributes)
```

Available options include:
- `kSecAttrAccessibleAfterFirstUnlock`: Available after first unlock until device restart
- `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`: Only available when device has a passcode
- `kSecAttrAccessibleWhenUnlocked`: Only available when device is unlocked
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`: most secure for local-only.

## Error Handling

Keychain operations can throw `KeychainError.unexpectedStatus(status, description)`. Typical codes include:

- -34018 (errSecMissingEntitlement): Missing keychain access group
- -25300 (errSecItemNotFound): Reading or updating non-existent items
- -25299 (errSecDuplicateItem): When creating an item that already exists

The Keychain wrapper provides detailed error information through `KeychainError`:

```swift
do {
    try store.set("value")
} catch KeychainError.unexpectedStatus(let status, let message) {
    // handle error
}
```

## Thread Safety

### ValueKeychainStore
`ValueKeychainStore` uses an internal lock, so `get()` and `set()` can be called from multiple threads safely.

### ObservedValueStore
Observers are stored in a threadsafe dictionary. However, callbacks run on a background thread, so dispatch to the main queue if UI work is needed:
```swift
_ = observedStore.observeChanges { newValue in
    DispatchQueue.main.async {
        // update UI
    }
}
```

## Sharing Between Apps

### App Groups
When sharing keychain items between multiple apps:

1. Configure the same keychain access group in both apps:
```swift
let store1 = ValueKeychainStore(
    accountName: "shared-account",
    accessGroup: "TEAM_ID.com.company.shared.keychain"
)
let store2 = ValueKeychainStore(
    accountName: "shared-account",
    accessGroup: "TEAM_ID.com.company.shared.keychain"
)
```
2. Migrate existing items if needed:
```swift
if let oldVal = try? oldStore.get() {
    try? sharedStore.set(oldVal)
    try? oldStore.set(nil)
}
```

## Working with Complex Data Types

While the base implementation stores String values, you can extend `ValueKeychainStore` to support other types.
For instance, the code below adds Codable support:

```swift
extension ValueKeychainStore {
    func setCodable<T: Encodable>(_ value: T) throws {
        let data = try JSONEncoder().encode(value)
        try set(String(data: data, encoding: .utf8))
    }
    
    func getCodable<T: Decodable>() throws -> T? {
        guard let string = try get(),
              let data = string.data(using: .utf8) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

## Topics

### Code

- ``Keychain``
- ``Keychain/KeychainError``
- ``Keychain/Observation``
- ``Keychain/ObservedValueStore``
- ``Keychain/ValueKeychainStore``
- ``Keychain/ValueStore``
