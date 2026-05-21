import Cocoa
import CoreServices

struct Browser: Identifiable {
    let id: String
    let name: String
    let icon: NSImage
    let bundleIdentifier: String
}

class BrowserManager {
    static let shared = BrowserManager()
    
    private var cachedBrowsers: [Browser]? = nil
    
    func getInstalledBrowsers() -> [Browser] {
        if let cached = cachedBrowsers { return cached }
        
        guard let handlers = LSCopyAllHandlersForURLScheme("http" as CFString)?.takeRetainedValue() as? [String] else {
            return []
        }
        
        var browsers: [Browser] = []
        let myBundleId = Bundle.main.bundleIdentifier ?? "com.user.BrowserSelector"
        
        for bundleId in handlers {
            if bundleId == myBundleId { continue } // Skip self
            
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                let name = FileManager.default.displayName(atPath: appURL.path)
                let nameWithoutExtension = (name as NSString).deletingPathExtension
                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                
                browsers.append(Browser(id: bundleId, name: nameWithoutExtension, icon: icon, bundleIdentifier: bundleId))
            }
        }
        
        // Remove duplicates and sort
        var uniqueBrowsers = [String: Browser]()
        for b in browsers {
            uniqueBrowsers[b.bundleIdentifier] = b
        }
        
        cachedBrowsers = uniqueBrowsers.values.sorted { $0.name < $1.name }
        return cachedBrowsers!
    }
    
    func open(url: URL, with browser: Browser) {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration) { _, error in
                if let error = error {
                    print("Failed to open URL: \(error.localizedDescription)")
                }
            }
        }
    }
}
