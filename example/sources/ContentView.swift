import Keychain
import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var storedValue = ""
    @State private var statusMessage = ""
    
    private let keychain = ValueKeychainStore(
        accountName: "example-demo-key",
        accessGroup: "23KN7M4FPW.group.dev.jano.apple"
    )
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Keychain Example")
                .font(.largeTitle)
                .padding()
            
            Text("Cross-platform Keychain demo app")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Current stored value:")
                    .font(.headline)
                
                Text(storedValue.isEmpty ? "No value stored" : storedValue)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 10) {
                TextField("Enter value to store", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Button("Store Value") {
                        Task {
                            await storeValue()
                        }
                    }
                    .disabled(inputText.isEmpty)
                    
                    Button("Clear Keychain") {
                        Task {
                            await clearValue()
                        }
                    }
                }
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mint.opacity(0.1))
        .task {
            await loadValue()
        }
    }
    
    private func storeValue() async {
        do {
            try await keychain.set(inputText)
            statusMessage = "Value stored successfully"
            inputText = ""
            await loadValue()
        } catch {
            statusMessage = "Error storing value: \(error.localizedDescription)"
        }
    }
    
    private func loadValue() async {
        do {
            let value = try await keychain.get()
            storedValue = value ?? ""
            statusMessage = value != nil ? "Value loaded from keychain" : "No value in keychain"
        } catch {
            statusMessage = "Error loading value: \(error.localizedDescription)"
            storedValue = ""
        }
    }
    
    private func clearValue() async {
        do {
            try await keychain.set(nil)
            storedValue = ""
            statusMessage = "Keychain cleared"
        } catch {
            statusMessage = "Error clearing keychain: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}