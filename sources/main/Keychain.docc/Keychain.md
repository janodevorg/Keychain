# ``Keychain``

Keychain wrapper.

## Overview

### Enable keychain sharing

To enable keychain item sharing:

- Enable Keychain Sharing in target > Signing & Capabilities. Click the plus sign to add the 
  capability Keychain Sharing.
- Set a value in “Keychain Groups” for each shared keychain item. The value must start with the 
  Bundle Seed ID, followed by an arbitrary string.

This creates a file <TargetName>.entitlements, pointed by Build Settings > Code Signing 
Entitlements. Here is the file I generated:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)boardapp.development.credentials</string>
    </array>
</dict>
</plist>
```

The $(AppIdentifierPrefix) will be replaced with your Team ID. The Team ID is listed in the Member Center:

![AppIdentifier](AppIdentifier)

The whole string for me is "PPSF6CNP8Q.dev.jano.keychain.example". Yours will be different.

### Usage 

Store a value as a generic password:
```swift
let account = "an-arbitrary-string"
let accessGroup = "PPSF6CNP8Q.dev.jano.keychain.example"
let store = ValueKeychainStore(accountName: account, accessGroup: accessGroup)
store.set("some value")
print(store.get()) // prints "some value"
```

Use the ObservedValueStore to react to value changes:
```swift
let accessGroup = "PPSF6CNP8Q.dev.jano.keychain.example"
let underlyingStore = ValueKeychainStore(accountName: account, accessGroup: accessGroup)
let store = await ObservedValueStore(valueStore: underlyingStore)
let observation = await store.observe { [weak self] value in
    print("Value changed to \(value)")
} 
try await store.set("bananas")
observation.stopObserving()
```

![Keychain](Keychain)

## Topics

### Code

- ``Keychain``
- ``Keychain/KeychainError``
- ``Keychain/Observation``
- ``Keychain/ObservedValueStore``
- ``Keychain/ValueKeychainStore``
- ``Keychain/ValueStore``
