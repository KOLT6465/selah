import AppKit
import SwiftUI

final class SelahAppDelegate: NSObject, NSApplicationDelegate {
#if DEBUG
    private var previewWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.arguments.contains("--ui-preview") else { return }
        let root = VersePopoverView(model: AppModel())
        let host = NSHostingView(rootView: root)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Selah Visual Test"
        window.contentView = host
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        previewWindow = window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            window.setContentSize(host.fittingSize)
            window.center()
        }
    }
#endif
}

@main
struct SelahApp: App {
    @NSApplicationDelegateAdaptor(SelahAppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            VersePopoverView(model: model)
                .preferredColorScheme(model.preferences.appearance.colorScheme)
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 6, weight: .bold))
                    .offset(x: 3, y: -2)
            }
                .accessibilityLabel("Selah — Verse of the Day")
        }
        .menuBarExtraStyle(.window)
    }
}

private extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
