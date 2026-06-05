import Cocoa
import CoreServices

enum BrowserType {
    case chromium
    case firefox
    case standard
}

struct Browser: Identifiable {
    let id: String
    let name: String
    let icon: NSImage
    let bundleIdentifier: String
    var profileId: String? = nil
    var browserType: BrowserType = .standard
}

class BrowserManager {
    static let shared = BrowserManager()
    
    private var cachedBrowsers: [Browser]? = nil
    
    private func fetchChromiumProfiles(bundleId: String) -> [(id: String, name: String)]? {
        let paths: [String: String] = [
            "com.google.Chrome": "~/Library/Application Support/Google/Chrome/Local State",
            "com.microsoft.edgemac": "~/Library/Application Support/Microsoft Edge/Local State",
            "com.brave.Browser": "~/Library/Application Support/BraveSoftware/Brave-Browser/Local State",
            "com.vivaldi.Vivaldi": "~/Library/Application Support/Vivaldi/Local State",
            "com.operasoftware.Opera": "~/Library/Application Support/com.operasoftware.Opera/Local State"
        ]
        
        guard let relativePath = paths[bundleId] else { return nil }
        let path = (relativePath as NSString).expandingTildeInPath
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = json["profile"] as? [String: Any],
              let infoCache = profile["info_cache"] as? [String: [String: Any]] else {
            return nil
        }
        
        var profiles: [(String, String)] = []
        for (dirName, info) in infoCache {
            let name = info["name"] as? String ?? ""
            profiles.append((dirName, name))
        }
        return profiles.isEmpty ? nil : profiles
    }
    
    private func fetchFirefoxProfiles() -> [(id: String, name: String)]? {
        let path = ("~/Library/Application Support/Firefox/profiles.ini" as NSString).expandingTildeInPath
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        
        var profiles: [(String, String)] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("Name=") {
                let name = String(line.dropFirst(5))
                profiles.append((name, name))
            }
        }
        return profiles.isEmpty ? nil : profiles
    }
    
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
        
        var uniqueBrowsers = [String: Browser]()
        for b in browsers {
            uniqueBrowsers[b.bundleIdentifier] = b
        }
        
        var finalBrowsers: [Browser] = []
        for b in uniqueBrowsers.values {
            if let chromiumProfiles = fetchChromiumProfiles(bundleId: b.bundleIdentifier) {
                if chromiumProfiles.count > 1 || (chromiumProfiles.count == 1 && !chromiumProfiles[0].name.isEmpty && chromiumProfiles[0].name != "Person 1") {
                    for p in chromiumProfiles {
                        let displayName = p.name.isEmpty ? b.name : "\(b.name) (\(p.name))"
                        finalBrowsers.append(Browser(id: "\(b.bundleIdentifier)_\(p.id)", name: displayName, icon: b.icon, bundleIdentifier: b.bundleIdentifier, profileId: p.id, browserType: .chromium))
                    }
                } else {
                    finalBrowsers.append(b)
                }
            } else if b.bundleIdentifier == "org.mozilla.firefox", let ffProfiles = fetchFirefoxProfiles() {
                if ffProfiles.count > 1 {
                    for p in ffProfiles {
                        finalBrowsers.append(Browser(id: "\(b.bundleIdentifier)_\(p.id)", name: "\(b.name) (\(p.name))", icon: b.icon, bundleIdentifier: b.bundleIdentifier, profileId: p.id, browserType: .firefox))
                    }
                } else {
                    finalBrowsers.append(b)
                }
            } else {
                finalBrowsers.append(b)
            }
        }
        
        cachedBrowsers = finalBrowsers.sorted { $0.name < $1.name }
        return cachedBrowsers!
    }
    
    func open(url: URL, with browser: Browser) {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) {
            
            // For browsers with profiles, LaunchServices often ignores command-line arguments if the app is already running.
            // By launching the internal executable directly via Process, the browser's own IPC handles routing the URL 
            // to the correct profile window.
            if let profileId = browser.profileId {
                let bundle = Bundle(url: appURL)
                if let executableURL = bundle?.executableURL {
                    let process = Process()
                    process.executableURL = executableURL
                    
                    if browser.browserType == .chromium {
                        process.arguments = ["--profile-directory=\(profileId)", url.absoluteString]
                    } else if browser.browserType == .firefox {
                        process.arguments = ["-P", profileId, url.absoluteString]
                    }
                    
                    do {
                        try process.run()
                        
                        // Ensure the app comes to the foreground
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: browser.bundleIdentifier).first {
                                runningApp.activate(options: .activateIgnoringOtherApps)
                            }
                        }
                        return
                    } catch {
                        print("Failed to run process: \(error.localizedDescription)")
                    }
                }
            }
            
            // Fallback to standard LaunchServices for non-profiled browsers
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration) { _, error in
                if let error = error {
                    print("Failed to open URL: \(error.localizedDescription)")
                }
            }
        }
    }
}
