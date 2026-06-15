import AppKit
import SwiftUI

private enum TerminalTheme {
    static let ink = Color(red: 0.07, green: 0.10, blue: 0.12)
    static let panel = Color(red: 0.10, green: 0.15, blue: 0.17)
    static let line = Color(red: 0.19, green: 0.28, blue: 0.31)
    static let glow = Color(red: 0.69, green: 1.0, blue: 0.75)
    static let glowDim = Color(red: 0.40, green: 0.79, blue: 0.53)
    static let text = Color(red: 0.91, green: 0.96, blue: 0.92)
    static let muted = Color(red: 0.55, green: 0.66, blue: 0.66)
    static let red = Color(red: 1.0, green: 0.35, blue: 0.30)
    static let yellow = Color(red: 1.0, green: 0.74, blue: 0.25)
    static let green = Color(red: 0.47, green: 0.84, blue: 0.40)
}

struct ContentView: View {
    @ObservedObject var scanner: ServerScanner
    @ObservedObject var loginItemManager: LoginItemManager

    var body: some View {
        VStack(spacing: 0) {
            header
            serverList
            footer
        }
        .background(TerminalTheme.ink)
        .frame(width: 430, height: 520)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("What The Port?")
                    .font(.custom("Jersey 10", size: 30))
                    .foregroundStyle(TerminalTheme.glow)
                    .shadow(color: TerminalTheme.glow.opacity(0.18), radius: 5, x: 0, y: 0)

                Text(scanner.isScanning ? "Scanning ports" : "\(scanner.servers.count) open \(scanner.servers.count == 1 ? "port" : "ports")")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(TerminalTheme.muted)
            }

            Spacer()

            Button {
                scanner.refresh()
            } label: {
                Image(systemName: scanner.isScanning ? "arrow.triangle.2.circlepath.circle" : "arrow.clockwise")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(TerminalTheme.glow)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .help("Refresh")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(TerminalTheme.panel)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TerminalTheme.line)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var serverList: some View {
        if scanner.servers.isEmpty {
            VStack(spacing: 12) {
                Text(scanner.isScanning ? ":?" : ":0")
                    .font(.custom("Jersey 10", size: 38))
                    .foregroundStyle(TerminalTheme.glow)
                    .shadow(color: TerminalTheme.glow.opacity(0.22), radius: 6, x: 0, y: 0)
                Text(scanner.isScanning ? "Scanning local ports..." : "No local HTTP servers found")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(TerminalTheme.muted)
                if let error = scanner.lastError {
                    Text(error)
                        .font(.caption.monospaced())
                        .foregroundStyle(TerminalTheme.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TerminalTheme.ink)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(scanner.servers) { server in
                        ServerRow(server: server) {
                            scanner.stop(server: server)
                        }
                        if server.id != scanner.servers.last?.id {
                            Rectangle()
                                .fill(TerminalTheme.line)
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .background(TerminalTheme.ink)
        }
    }

    private var footer: some View {
        HStack {
            Button {
                loginItemManager.isEnabled.toggle()
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(loginItemManager.isEnabled ? TerminalTheme.glowDim : TerminalTheme.panel)
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(
                                        loginItemManager.isEnabled ? TerminalTheme.glowDim : TerminalTheme.muted.opacity(0.75),
                                        lineWidth: 1.4
                                    )
                            }
                            .frame(width: 18, height: 18)
                        if loginItemManager.isEnabled {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(TerminalTheme.ink)
                        }
                    }
                    Text("Launch at login")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .buttonStyle(TerminalButtonStyle())
        }
        .font(.system(size: 12))
        .foregroundStyle(TerminalTheme.text)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(TerminalTheme.panel)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TerminalTheme.line)
                .frame(height: 1)
        }
    }
}

struct ServerRow: View {
    let server: ServerInfo
    let onStop: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 13) {
                Text(":\(server.port)")
                    .font(.custom("Jersey 10", size: 28))
                    .foregroundStyle(TerminalTheme.glowDim)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 3) {
                    Text(server.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TerminalTheme.text)
                        .lineLimit(1)
                    Text("PID \(server.pid) · \(server.command)")
                        .font(.caption.monospaced())
                        .foregroundStyle(TerminalTheme.muted)
                }
                Spacer()

                HStack(alignment: .center, spacing: 12) {
                    if let statusCode = server.statusCode {
                        Text("\(statusCode)")
                            .font(.custom("Jersey 10", size: 18))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor(statusCode).opacity(0.18))
                            .foregroundStyle(statusColor(statusCode))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    Button(role: .destructive) {
                        onStop()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TerminalTheme.red)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    .help("Stop this server")
                }
            }

            if let preview = server.bodyPreview, !preview.isEmpty {
                Text(preview)
                    .font(.caption)
                    .foregroundStyle(TerminalTheme.muted)
                    .lineLimit(2)
                    .padding(.vertical, 10)
            }

            HStack(spacing: 18) {
                Button {
                    NSWorkspace.shared.open(server.localURL)
                } label: {
                    CompactActionLabel(title: "Open", systemImage: "safari")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(TerminalTheme.glowDim)
                .pointingHandCursor()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(server.localURL.absoluteString, forType: .string)
                } label: {
                    CompactActionLabel(title: "Copy URL", systemImage: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(TerminalTheme.glowDim)
                .pointingHandCursor()
            }
            .padding(.top, server.bodyPreview?.isEmpty == false ? 0 : 10)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var rowBackground: Color {
        let base = isHovered ? TerminalTheme.panel.opacity(0.72) : TerminalTheme.ink
        guard let statusCode = server.statusCode else {
            return base
        }

        switch statusCode {
        case 400..<500:
            return TerminalTheme.yellow.opacity(isHovered ? 0.13 : 0.07)
        case 500...:
            return TerminalTheme.red.opacity(isHovered ? 0.14 : 0.075)
        default:
            return base
        }
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300:
            return TerminalTheme.green
        case 300..<400:
            return TerminalTheme.glowDim
        case 400..<500:
            return TerminalTheme.yellow
        default:
            return TerminalTheme.red
        }
    }
}

private struct TrafficLight: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
    }
}

private struct TerminalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(TerminalTheme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(configuration.isPressed ? TerminalTheme.line : TerminalTheme.muted.opacity(0.34))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private extension View {
    func pointingHandCursor() -> some View {
        onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

struct CompactActionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
            Text(title)
        }
    }
}
