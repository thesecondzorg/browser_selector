import SwiftUI

struct ContentView: View {
    let url: URL
    let browsers: [Browser]
    let onSelect: (Browser) -> Void
    let onCancel: () -> Void
    
    @State private var hoveredBrowserId: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Open link in...")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(url.absoluteString)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            // Browsers Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)], spacing: 20) {
                ForEach(browsers) { browser in
                    BrowserButton(
                        browser: browser,
                        isHovered: hoveredBrowserId == browser.id,
                        onHover: { hovering in
                            if hovering {
                                hoveredBrowserId = browser.id
                            } else if hoveredBrowserId == browser.id {
                                hoveredBrowserId = nil
                            }
                        },
                        action: {
                            onSelect(browser)
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding()
            }
            .background(VisualEffectView().ignoresSafeArea())
        }
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct BrowserButton: View {
    let browser: Browser
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(nsImage: browser.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                
                Text(browser.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover(perform: onHover)
    }
}

// Helper for native blurry background
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .windowBackground
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
