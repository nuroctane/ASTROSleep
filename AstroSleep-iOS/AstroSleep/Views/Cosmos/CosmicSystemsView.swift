import SwiftUI
import WebKit

// MARK: - Cosmic Systems Tab
/// Offline WebView hosting the shared Three.js systems sky (not personal natal dump).
/// Spec: documentation/COSMIC_SYSTEMS_3D_TAB.md · DESIGN.md Digital Sea.

struct CosmicSystemsView: View {
    var body: some View {
        ZStack {
            Color(red: 7 / 255, green: 11 / 255, blue: 20 / 255)
                .ignoresSafeArea()
            CosmicSystemsWebView()
                .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - WKWebView bridge

struct CosmicSystemsWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: config)
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
        // Prefer bundle resource folder "cosmic-systems"
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "cosmic-systems") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            return
        }
        // Fallback: flat resource
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            return
        }
        // Dev fallback message
        let html = """
        <html><body style="background:#070B14;color:#9AA8C0;font-family:-apple-system;padding:24px">
        <h3 style="color:#E8EEF8">Cosmic Systems bundle missing</h3>
        <p>Add <code>Resources/cosmic-systems/</code> to the Xcode target (Copy Bundle Resources).</p>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

#if DEBUG
struct CosmicSystemsView_Previews: PreviewProvider {
    static var previews: some View {
        CosmicSystemsView()
    }
}
#endif
