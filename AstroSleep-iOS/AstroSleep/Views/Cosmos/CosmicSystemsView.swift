import SwiftUI
import WebKit

// MARK: - Cosmic Systems Tab
/// Offline WebView hosting the shared Three.js systems sky (not personal natal dump).
/// Spec: documentation/COSMIC_SYSTEMS_3D_TAB.md · DESIGN.md Digital Sea.
///
/// **Xcode:** add `Resources/cosmic-systems` folder to the app target
/// (File Inspector → Target Membership, or Copy Bundle Resources).
/// See `documentation/XCODE_COSMIC_BUNDLE.md`.

struct CosmicSystemsView: View {
    var body: some View {
        ZStack {
            Color(red: 7 / 255, green: 11 / 255, blue: 20 / 255)
                .ignoresSafeArea()
            CosmicSystemsWebView()
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - WKWebView bridge

struct CosmicSystemsWebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 7 / 255, green: 11 / 255, blue: 20 / 255, alpha: 1)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        loadBundle(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func loadBundle(into webView: WKWebView) {
        // 1) Folder reference cosmic-systems/index.html
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "cosmic-systems") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            return
        }
        // 2) Flat resource
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            return
        }
        // 3) ResourceURL walk (some Xcode folder setups nest differently)
        if let resourceURL = Bundle.main.resourceURL {
            let candidate = resourceURL.appendingPathComponent("cosmic-systems/index.html")
            if FileManager.default.fileExists(atPath: candidate.path) {
                webView.loadFileURL(candidate, allowingReadAccessTo: candidate.deletingLastPathComponent())
                return
            }
        }
        let html = """
        <html><body style="background:#070B14;color:#9AA8C0;font-family:-apple-system;padding:24px">
        <h3 style="color:#E8EEF8">Cosmic Systems bundle missing</h3>
        <p>In Xcode: add <code>AstroSleep/Resources/cosmic-systems</code> to the app target
        (Copy Bundle Resources). See documentation/XCODE_COSMIC_BUNDLE.md.</p>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail provisionalNavigation: WKNavigation!, withError error: Error) {
            #if DEBUG
            print("CosmicSystems WebView fail: \(error.localizedDescription)")
            #endif
        }
    }
}
