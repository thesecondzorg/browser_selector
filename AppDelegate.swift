import Cocoa
import SwiftUI

class SelectorWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        
        // Pre-fetch browsers in the background so it opens instantly when a link is clicked
        DispatchQueue.global(qos: .userInitiated).async {
            _ = BrowserManager.shared.getInstalledBrowsers()
        }
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }
        
        // We must perform UI updates on the main thread
        DispatchQueue.main.async {
            self.showBrowserSelector(for: url)
        }
    }
    
    func showBrowserSelector(for url: URL) {
        let browsers = BrowserManager.shared.getInstalledBrowsers()
        
        let contentView = ContentView(
            url: url,
            browsers: browsers,
            onSelect: { [weak self] browser in
                BrowserManager.shared.open(url: url, with: browser)
                self?.window?.orderOut(nil)
            },
            onCancel: { [weak self] in
                self?.window?.orderOut(nil)
            }
        )
        
        if self.window == nil {
            let hostingController = NSHostingController(rootView: contentView)
            
            let win = SelectorWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 200),
                styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            win.contentViewController = hostingController
            win.setContentSize(hostingController.view.fittingSize)
            win.center()
            
            win.titlebarAppearsTransparent = true
            win.titleVisibility = .hidden
            win.isMovableByWindowBackground = true
            win.backgroundColor = .windowBackgroundColor
            
            // Critical for background apps: ensure it always appears on top and on all spaces
            win.level = .floating
            win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            self.window = win
        } else {
            if let hc = self.window?.contentViewController as? NSHostingController<ContentView> {
                hc.rootView = contentView
                self.window?.setContentSize(hc.view.fittingSize)
                self.window?.center()
            }
        }
        
        NSApp.activate(ignoringOtherApps: true)
        self.window?.makeKeyAndOrderFront(nil)
    }
}
