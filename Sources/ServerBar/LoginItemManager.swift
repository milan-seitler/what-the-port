import Foundation

final class LoginItemManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            setLaunchAtLogin(isEnabled)
        }
    }

    private let label = "io.github.milanseitler.whattheport"
    private let plistURL: URL

    init() {
        plistURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/io.github.milanseitler.whattheport.plist")
        isEnabled = FileManager.default.fileExists(atPath: plistURL.path)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try FileManager.default.createDirectory(
                    at: plistURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                let executable = Bundle.main.bundleURL.path
                let plist = """
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    <key>Label</key>
                    <string>\(label)</string>
                    <key>ProgramArguments</key>
                    <array>
                        <string>/usr/bin/open</string>
                        <string>\(executable)</string>
                    </array>
                    <key>RunAtLoad</key>
                    <true/>
                </dict>
                </plist>
                """
                try plist.write(to: plistURL, atomically: true, encoding: .utf8)
            } else if FileManager.default.fileExists(atPath: plistURL.path) {
                try FileManager.default.removeItem(at: plistURL)
            }
        } catch {
            isEnabled = FileManager.default.fileExists(atPath: plistURL.path)
        }
    }
}
