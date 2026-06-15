import SwiftUI

struct ContentView: View {
    @ObservedObject var scanner: ServerScanner
    @ObservedObject var loginItemManager: LoginItemManager

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            serverList
            Divider()
            footer
        }
        .frame(width: 430, height: 520)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("What The Port?")
                    .font(.headline)
                Text("\(scanner.servers.count) HTTP \(scanner.servers.count == 1 ? "server" : "servers")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                scanner.refresh()
            } label: {
                Image(systemName: scanner.isScanning ? "arrow.triangle.2.circlepath.circle" : "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh")
        }
        .padding(14)
    }

    @ViewBuilder
    private var serverList: some View {
        if scanner.servers.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: scanner.isScanning ? "magnifyingglass.circle" : "checkmark.circle")
                    .font(.system(size: 34))
                    .foregroundStyle(.secondary)
                Text(scanner.isScanning ? "Scanning local ports..." : "No local HTTP servers found")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if let error = scanner.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(scanner.servers) { server in
                        ServerRow(server: server) {
                            scanner.stop(server: server)
                        }
                        Divider()
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Toggle("Launch at login", isOn: $loginItemManager.isEnabled)
                .toggleStyle(.checkbox)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(14)
    }
}

struct ServerRow: View {
    let server: ServerInfo
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(server.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(":\(server.port) • PID \(server.pid) • \(server.command)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let statusCode = server.statusCode {
                    Text("\(statusCode)")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(statusColor(statusCode).opacity(0.16))
                        .foregroundStyle(statusColor(statusCode))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                Button(role: .destructive) {
                    onStop()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.borderless)
                .help("Stop this server")
            }

            if let preview = server.bodyPreview, !preview.isEmpty {
                Text(preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Button {
                    NSWorkspace.shared.open(server.localURL)
                } label: {
                    CompactActionLabel(title: "Open", systemImage: "safari")
                }
                .buttonStyle(.link)
                .font(.caption)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(server.localURL.absoluteString, forType: .string)
                } label: {
                    CompactActionLabel(title: "Copy URL", systemImage: "doc.on.doc")
                }
                .buttonStyle(.link)
                .font(.caption)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300:
            return .green
        case 300..<400:
            return .blue
        case 400..<500:
            return .orange
        default:
            return .red
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
