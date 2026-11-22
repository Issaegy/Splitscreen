import SwiftUI
import UIKit
import WebKit
import Combine

/// Eine Bildschirmhälfte. Jede Hälfte besitzt ihren eigenen Browser
/// (WKWebView), der beim Tauschen/Drehen erhalten bleibt – so geht nichts
/// verloren (Videos, Logins, Scrollposition).
@MainActor
final class Pane: NSObject, ObservableObject, Identifiable {
    let id = UUID()

    @Published private(set) var kind: PaneKind = .empty
    @Published private(set) var title = ""
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var isLoading = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var desktopMode = false

    let webView: WKWebView

    /// Wird aufgerufen, wenn sich der gespeicherte Zustand ändert.
    var onChange: (() -> Void)?

    private var cancellables = Set<AnyCancellable>()

    var isWeb: Bool { webURL != nil }

    var webURL: URL? {
        if case .web(let url) = kind { return url }
        return nil
    }

    init(kind: PaneKind) {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // Manche Seiten (z. B. Google-Login) lehnen eingebettete Browser ab,
        // wenn der Safari-Zusatz im User-Agent fehlt.
        config.applicationNameForUserAgent = "Version/17.0 Mobile/15E148 Safari/604.1"
        // In einer halben Bildschirmbreite passen mobile Seiten besser.
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        webView = WKWebView(frame: .zero, configuration: config)

        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        webView.publisher(for: \.canGoBack).assign(to: &$canGoBack)
        webView.publisher(for: \.canGoForward).assign(to: &$canGoForward)
        webView.publisher(for: \.isLoading).assign(to: &$isLoading)
        webView.publisher(for: \.estimatedProgress).assign(to: &$progress)
        webView.publisher(for: \.title).map { $0 ?? "" }.assign(to: &$title)
        webView.publisher(for: \.url)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in self?.urlDidChange(url) }
            .store(in: &cancellables)

        show(kind)
    }

    /// Zeigt neuen Inhalt in dieser Hälfte an.
    func show(_ newKind: PaneKind) {
        kind = newKind
        switch newKind {
        case .web(let url):
            if webView.url != url {
                webView.load(URLRequest(url: url))
            }
        case .empty, .notes:
            // Seite entladen, damit z. B. ein Video nicht weiterspielt.
            webView.stopLoading()
            if let blank = URL(string: "about:blank") {
                webView.load(URLRequest(url: blank))
            }
        }
        onChange?()
    }

    func reloadOrStop() {
        if isLoading {
            webView.stopLoading()
        } else {
            webView.reload()
        }
    }

    func toggleDesktopMode() {
        desktopMode.toggle()
        webView.reload()
    }

    private func urlDidChange(_ url: URL?) {
        guard isWeb,
              let url,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return }

        if kind != .web(url) {
            kind = .web(url)
            onChange?()
        }
    }
}

extension Pane: WKNavigationDelegate, WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        preferences.preferredContentMode = desktopMode ? .desktop : .mobile

        // Links wie mailto:, tel: oder App-Links an das System weitergeben.
        let webSchemes: Set<String> = ["http", "https", "about", "data", "blob", "javascript"]
        if let url = navigationAction.request.url,
           let scheme = url.scheme?.lowercased(),
           !webSchemes.contains(scheme) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel, preferences)
            return
        }

        decisionHandler(.allow, preferences)
    }

    /// Links, die ein neues Fenster öffnen wollen (target="_blank"),
    /// werden in derselben Hälfte geöffnet.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
