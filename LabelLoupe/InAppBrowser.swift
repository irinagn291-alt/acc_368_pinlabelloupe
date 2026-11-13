import SwiftUI
import UIKit
import WebKit
import OSLog

struct InAppBrowser: View {
    let url: String
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            BrowserControllerView(urlString: url, isLoading: $isLoading)
                .ignoresSafeArea()
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView().scaleEffect(1.5).tint(.white)
                }
                .accessibilityIdentifier("browser.loading")
            }
        }
    }
}

private struct BrowserControllerView: UIViewControllerRepresentable {
    let urlString: String
    @Binding var isLoading: Bool

    func makeUIViewController(context: Context) -> BrowserViewController {
        let controller = BrowserViewController()
        controller.delegate = context.coordinator
        controller.loadURL(urlString)
        return controller
    }

    func updateUIViewController(_ controller: BrowserViewController, context: Context) {}

    static func dismantleUIViewController(_ controller: BrowserViewController, coordinator: Coordinator) {
        controller.stop()
    }

    func makeCoordinator() -> Coordinator { Coordinator(isLoading: $isLoading) }

    final class Coordinator: BrowserViewControllerDelegate {
        @Binding private var isLoading: Bool

        init(isLoading: Binding<Bool>) { _isLoading = isLoading }

        func webViewDidStartLoading() { isLoading = true }
        func webViewDidFinishLoading() { isLoading = false }
    }
}

@MainActor
private protocol BrowserViewControllerDelegate: AnyObject {
    func webViewDidStartLoading()
    func webViewDidFinishLoading()
}

private final class BrowserViewController: UIViewController {
    weak var delegate: BrowserViewControllerDelegate?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "App", category: "WebView")
    private var webView: WKWebView!
    private var pendingURLString: String?
    private var didStartLoad = false
    private var lastRequest: URLRequest?
    private var failureView: UIView?
    private var observedCookies: [HTTPCookie] = []
    private var loadTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = AppEndpoints.defaultUserAgent
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.accessibilityIdentifier = "browser.webView"
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        if let urlString = pendingURLString {
            pendingURLString = nil
            loadURL(urlString)
        }
    }

    func loadURL(_ value: String) {
        guard webView != nil else { pendingURLString = value; return }
        guard !didStartLoad else { return }
        guard let url = ContentURL.validated(value) else {
            delegate?.webViewDidFinishLoading()
            return
        }
        didStartLoad = true
        let request = URLRequest(url: url)
        lastRequest = request
        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            BrowserSession.restore()
            let store = webView.configuration.websiteDataStore.httpCookieStore
            for cookie in HTTPCookieStorage.shared.cookies ?? [] { await store.setCookie(cookie) }
            observedCookies = await store.allCookies()
            guard !Task.isCancelled else { return }
            store.add(self)
            webView.load(request)
        }
    }

    func stop() {
        loadTask?.cancel()
        webView?.configuration.websiteDataStore.httpCookieStore.remove(self)
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        delegate = nil
    }

    @objc private func reloadPage() {
        failureView?.removeFromSuperview()
        failureView = nil
        if let lastRequest { webView.load(lastRequest) }
        else { webView.reload() }
    }

    private func loadingFailed(_ error: Error) {
        let failure = error as NSError
        guard failure.domain != NSURLErrorDomain || failure.code != NSURLErrorCancelled else { return }
        delegate?.webViewDidFinishLoading()
        logger.error("Navigation failed: \(failure.domain, privacy: .public) (\(failure.code))")
        if let failedURL = failure.userInfo[NSURLErrorFailingURLErrorKey] as? URL,
           ContentURL.validated(failedURL.absoluteString) != nil {
            lastRequest = URLRequest(url: failedURL)
        }
        failureView?.removeFromSuperview()
        let message = UILabel()
        message.text = failure.domain == NSURLErrorDomain && failure.code == NSURLErrorAppTransportSecurityRequiresSecureConnection
            ? "This page requires a secure connection." : "Unable to load page. Try again."
        message.textColor = .label
        message.font = .preferredFont(forTextStyle: .body)
        message.textAlignment = .center
        message.numberOfLines = 0
        let retry = UIButton(type: .system)
        retry.setTitle("Retry", for: .normal)
        retry.accessibilityIdentifier = "browser.retry"
        retry.addTarget(self, action: #selector(reloadPage), for: .touchUpInside)
        let panel = UIStackView(arrangedSubviews: [message, retry])
        panel.axis = .vertical
        panel.spacing = 12
        panel.backgroundColor = .systemBackground
        panel.layer.cornerRadius = 16
        panel.isLayoutMarginsRelativeArrangement = true
        panel.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 16, right: 20)
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            panel.centerYAnchor.constraint(equalTo: webView.centerYAnchor),
            panel.widthAnchor.constraint(lessThanOrEqualTo: webView.widthAnchor, constant: -40),
            panel.widthAnchor.constraint(lessThanOrEqualToConstant: 340)
        ])
        failureView = panel
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else {
            decisionHandler(.cancel)
            return
        }
        if ["http", "https", "about", "blob"].contains(scheme) {
            if navigationAction.targetFrame?.isMainFrame != false,
               ContentURL.validated(url.absoluteString) != nil { lastRequest = navigationAction.request }
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            if ["mailto", "tel", "sms"].contains(scheme) || navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url)
            }
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        failureView?.removeFromSuperview()
        failureView = nil
        delegate?.webViewDidStartLoading()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.webViewDidFinishLoading()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingFailed(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingFailed(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { reloadPage() }
}

extension BrowserViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url,
           ContentURL.validated(url.absoluteString) != nil { webView.load(navigationAction.request) }
        return nil
    }
}

extension BrowserViewController: WKHTTPCookieStoreObserver {
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        Task { @MainActor in
            let cookies = await cookieStore.allCookies()
            for previous in observedCookies where !cookies.contains(where: {
                $0.name == previous.name && $0.domain == previous.domain && $0.path == previous.path
            }) { HTTPCookieStorage.shared.deleteCookie(previous) }
            observedCookies = cookies
            for cookie in cookies { HTTPCookieStorage.shared.setCookie(cookie) }
            BrowserSession.persist()
        }
    }
}
