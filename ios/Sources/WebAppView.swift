import SwiftUI
import WebKit

/// Cała aplikacja to jeden plik index.html wczytany z bundle'a.
/// Nic nie idzie do sieci — dźwięk jest syntezowany w Web Audio.
struct WebAppView: UIViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        // Bez tego Web Audio nie ruszy bez dodatkowego gestu w środku strony.
        cfg.mediaTypesRequiringUserActionForPlayback = []

        let web = WKWebView(frame: .zero, configuration: cfg)
        web.uiDelegate = context.coordinator
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        let bg = UIColor(red: 0x0A/255, green: 0x09/255, blue: 0x08/255, alpha: 1)
        web.backgroundColor = bg
        web.scrollView.backgroundColor = bg
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.showsVerticalScrollIndicator = false
        web.allowsBackForwardNavigationGestures = false
        if #available(iOS 16.4, *) { web.isInspectable = true }

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            web.loadHTMLString(
                "<body style=\"background:#0A0908;color:#F6EFE6;font:16px -apple-system;padding:24px\">"
                + "<h2>Brak index.html w pakiecie</h2>"
                + "<p>Zasób nie trafił do bundle'a — sprawdź sekcję resources w ios/project.yml.</p></body>",
                baseURL: nil)
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        /// Stroik prosi o mikrofon przez getUserMedia. Bez tej zgody
        /// WebKit odrzuca prośbę, zanim iOS zdąży pokazać systemowy alert.
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(type == .microphone ? .grant : .deny)
        }

        /// Aplikacja jest offline — nic nie powinno wychodzić na zewnątrz.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
            decisionHandler(url.isFileURL || url.scheme == "about" ? .allow : .cancel)
        }
    }
}
