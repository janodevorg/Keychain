import OSLog

enum LoggerFactory: String {
    case keychain

    // returns a Logger instance whose category is the classname
    func logger(classname: String = #fileID) -> Logger {
        let className = classname.components(separatedBy: ".")
            .last?.components(separatedBy: "/")
            .last?.replacingOccurrences(of: "swift", with: "")
            .trimmingCharacters(in: .punctuationCharacters) ?? ""
        return Logger(subsystem: rawValue, category: className)
    }
}
