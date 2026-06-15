import Foundation

@MainActor
final class ServerScanner: ObservableObject {
    @Published private(set) var servers: [ServerInfo] = []
    @Published private(set) var isScanning = false
    @Published var lastError: String?

    private var timer: Timer?

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        guard !isScanning else { return }
        isScanning = true
        lastError = nil

        Task {
            do {
                let listeners = try await ListenerDetector.findListeners()
                let httpServers = await HTTPProbe.probe(listeners: listeners)
                await MainActor.run {
                    self.servers = httpServers.sorted { $0.port < $1.port }
                    self.isScanning = false
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                    self.isScanning = false
                }
            }
        }
    }

    func stop(server: ServerInfo) {
        ProcessKiller.terminate(pid: server.pid)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refresh()
        }
    }
}

struct Listener: Hashable {
    let port: Int
    let pid: Int32
    let command: String
}

enum ListenerDetector {
    static func findListeners() async throws -> [Listener] {
        let output = try run("/usr/sbin/lsof", arguments: ["-nP", "-iTCP", "-sTCP:LISTEN"])
        var listenersByPort: [Int: Listener] = [:]

        for line in output.split(separator: "\n").dropFirst() {
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard parts.count >= 9,
                  let pid = Int32(parts[1]) else {
                continue
            }

            let command = String(parts[0])
            let name = parts[8...].joined(separator: " ")
            guard let port = extractPort(from: name),
                  !isSystemNoise(command: command, port: port) else {
                continue
            }

            listenersByPort[port] = Listener(port: port, pid: pid, command: command)
        }

        return Array(listenersByPort.values)
    }

    private static func extractPort(from endpoint: String) -> Int? {
        guard let colon = endpoint.lastIndex(of: ":") else { return nil }
        let suffix = endpoint[endpoint.index(after: colon)...]
        let digits = suffix.prefix { $0.isNumber }
        return Int(digits)
    }

    private static func isSystemNoise(command: String, port: Int) -> Bool {
        let ignoredCommands = ["ControlCe", "rapportd", "sharingd"]
        if ignoredCommands.contains(where: { command.localizedCaseInsensitiveContains($0) }) {
            return true
        }
        return port == 5000 || port == 7000
    }

    private static func run(_ launchPath: String, arguments: [String]) throws -> String {
        let process = Process()
        let output = Pipe()
        let error = Pipe()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = error

        try process.run()
        process.waitUntilExit()

        let data = output.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

enum HTTPProbe {
    static func probe(listeners: [Listener]) async -> [ServerInfo] {
        await withTaskGroup(of: ServerInfo?.self) { group in
            for listener in listeners {
                group.addTask {
                    await probe(listener: listener)
                }
            }

            var results: [ServerInfo] = []
            for await result in group {
                if let result {
                    results.append(result)
                }
            }
            return results
        }
    }

    private static func probe(listener: Listener) async -> ServerInfo? {
        guard let url = URL(string: "http://127.0.0.1:\(listener.port)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 1.5
        request.setValue("WhatThePort/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }

            let body = String(data: data.prefix(4096), encoding: .utf8) ?? ""
            return ServerInfo(
                id: "\(listener.pid)-\(listener.port)",
                port: listener.port,
                pid: listener.pid,
                command: listener.command,
                title: extractTitle(from: body),
                statusCode: http.statusCode,
                contentType: http.value(forHTTPHeaderField: "Content-Type"),
                bodyPreview: summarize(body),
                lastChecked: Date()
            )
        } catch {
            return nil
        }
    }

    private static func extractTitle(from html: String) -> String {
        guard let range = html.range(of: #"<title[^>]*>(.*?)</title>"#, options: [.regularExpression, .caseInsensitive]) else {
            return ""
        }
        let raw = String(html[range])
            .replacingOccurrences(of: #"<\/?title[^>]*>"#, with: "", options: [.regularExpression, .caseInsensitive])
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func summarize(_ body: String) -> String {
        body
            .replacingOccurrences(of: #"<script[\s\S]*?</script>"#, with: " ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"<style[\s\S]*?</style>"#, with: " ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ProcessKiller {
    static func terminate(pid: Int32) {
        Darwin.kill(pid, SIGTERM)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            if Darwin.kill(pid, 0) == 0 {
                Darwin.kill(pid, SIGKILL)
            }
        }
    }
}
