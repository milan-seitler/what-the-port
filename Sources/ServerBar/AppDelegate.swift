import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let scanner = ServerScanner()
    private let loginItemManager = LoginItemManager()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        scanner.start()
        configureStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        scanner.stop()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "network", accessibilityDescription: "ServerBar")
        item.button?.action = #selector(togglePopover)
        item.button?.target = self
        statusItem = item

        let root = ContentView(scanner: scanner, loginItemManager: loginItemManager)
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 430, height: 520)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: root)
        self.popover = popover
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            startEventMonitoring()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        stopEventMonitoring()
    }

    private func startEventMonitoring() {
        stopEventMonitoring()

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self,
                  let popover = self.popover,
                  popover.isShown else {
                return event
            }

            let popoverWindow = popover.contentViewController?.view.window
            let statusWindow = self.statusItem?.button?.window
            if event.window !== popoverWindow && event.window !== statusWindow {
                self.closePopover()
            }
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closePopover()
            }
        }
    }

    private func stopEventMonitoring() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }

    func popoverDidClose(_ notification: Notification) {
        stopEventMonitoring()
    }
}
