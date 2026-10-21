import SwiftUI
import UIKit
import WebKit

/// Cała aplikacja to jeden plik index.html z bundle'a, podawany przez
/// LocalServer na http://127.0.0.1 — dzięki temu stroik ma dostęp do mikrofonu.
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
        context.coordinator.webView = web
        web.isOpaque = false
        let bg = UIColor(red: 0x0A/255, green: 0x09/255, blue: 0x08/255, alpha: 1)
        web.backgroundColor = bg
        web.scrollView.backgroundColor = bg
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.showsVerticalScrollIndicator = false
        web.allowsBackForwardNavigationGestures = false
        if #available(iOS 16.4, *) { web.isInspectable = true }

        context.coordinator.load()
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        weak var webView: WKWebView?
        private var observer: NSObjectProtocol?
        private var retried = false

        override init() {
            super.init()
            // Po dłuższym uśpieniu system potrafi zamknąć nasłuch. Upewnij się,
            // że serwer żyje, zanim WebKit spróbuje cokolwiek przeładować.
            observer = NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil, queue: .main) { [weak self] _ in
                guard let self = self, let web = self.webView else { return }
                LocalServer.shared.start { ok in
                    if ok && web.url == nil { self.load() }
                }
            }
        }

        deinit {
            if let o = observer { NotificationCenter.default.removeObserver(o) }
        }

        /// Najpierw serwer lokalny (mikrofon działa). Awaryjnie file:// —
        /// wtedy działa wszystko poza stroikiem.
        func load() {
            guard let web = webView else { return }
            LocalServer.shared.start { ok in
                if ok {
                    let url = LocalServer.shared.baseURL.appendingPathComponent("index.html")
                    web.load(URLRequest(url: url))
                } else if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
                    web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
                } else {
                    web.loadHTMLString(
                        "<body style=\"background:#0A0908;color:#F6EFE6;font:16px -apple-system;padding:24px\">"
                        + "<h2>Brak index.html w pakiecie</h2>"
                        + "<p>Zasób nie trafił do bundle'a — sprawdź sekcję resources w ios/project.yml.</p></body>",
                        baseURL: nil)
                }
            }
        }

        /// Stroik prosi o mikrofon przez getUserMedia. Bez tej zgody WebKit
        /// odrzuca prośbę, zanim iOS zdąży pokazać systemowy alert.
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(type == .microphone ? .grant : .deny)
        }

        /// Aplikacja jest offline — dozwolone tylko bundle i pętla zwrotna.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
            let loopback = url.host == "127.0.0.1" && url.port == Int(LocalServer.port)
            let allowed = url.isFileURL || url.scheme == "about" || loopback
            decisionHandler(allowed ? .allow : .cancel)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            retried = false
        }

        /// Serwer mógł jeszcze nie zdążyć wstać — jedna ponowna próba, nie pętla.
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            guard !retried else { return }
            retried = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.load() }
        }

        /// WebKit ubił proces strony (zwykle brak pamięci w tle) — wczytaj od nowa,
        /// ale dopiero gdy serwer na pewno nasłuchuje.
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            load()
        }
    }
}
