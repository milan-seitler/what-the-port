import AppKit
import CoreText
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
        registerBundledFonts()
        scanner.start()
        configureStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        scanner.stop()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = makeBundledMenuBarIcon() {
            item.button?.image = image
        }
        item.button?.toolTip = "What The Port?"
        item.button?.action = #selector(togglePopover)
        item.button?.target = self
        statusItem = item

        let root = ContentView(scanner: scanner, loginItemManager: loginItemManager)
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 430, height: 520)
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: root)
        self.popover = popover
    }

    private func registerBundledFonts() {
        for fontName in ["Jersey10-Regular"] {
            guard let fontURL = Bundle.module.url(forResource: fontName, withExtension: "ttf") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }

    private func makeBundledMenuBarIcon() -> NSImage? {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        var loadedRepresentation = false

        for resourceName in ["Icon", "Icon@2x", "Icon@3x"] {
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "png"),
                  let data = try? Data(contentsOf: url),
                  let representation = NSBitmapImageRep(data: data) else {
                continue
            }
            representation.size = size
            image.addRepresentation(representation)
            loadedRepresentation = true
        }

        guard loadedRepresentation else {
            return nil
        }

        image.size = size
        image.isTemplate = true
        image.accessibilityDescription = "What The Port?"
        return image
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
