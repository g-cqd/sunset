import AppKit
import SunsetPrivate
import WebKit

/// The page's view: made the first time the page is shown, with what Sunset sets on every page, and watched for what the page says of
/// itself (its title, address, progress).
extension WebContent {
    func makeWebView(configuration given: WKWebViewConfiguration?) {
        let configuration = given ?? WKWebViewConfiguration()
        if given == nil {
            configuration.websiteDataStore = settings.privacy.map(PrivateStores.store(for:)) ?? .default()
        }
        configuration.applicationNameForUserAgent = settings.applicationName
        LinkHover.install(on: configuration, for: self)
        WebDeveloperExtras.set(settings.developer, on: configuration.preferences)
        WebPermissionHooks.enable(on: configuration.preferences)
        WebFrameRate.set(fullRate: settings.fullFrameRate, on: configuration.preferences)
        // Pop-ups without a click reach Sunset, which decides by the site's answer; sound does not play on its own unless the site may.
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        // A video, or an element the page asks to, can fill the screen (roadmap 0029 step 3).
        configuration.preferences.isElementFullscreenEnabled = true
        if given == nil {
            let host = url?.host()
            configuration.mediaTypesRequiringUserActionForPlayback =
                permissions.answer(.autoplay, for: host) == .allow ? [] : .audio
        }
        let view = SunsetWebView(frame: .zero, configuration: configuration)
        view.customUserAgent = agent(for: url).userAgent
        view.isInspectable = settings.developer
        view.allowsBackForwardNavigationGestures = true
        view.allowsMagnification = true
        view.offersPrivateTab = !isPrivate
        view.onFocus = { [weak self] in self?.onFocusRequest() }
        let coordinator = WebCoordinator(content: self)
        view.navigationDelegate = coordinator
        view.uiDelegate = coordinator
        self.coordinator = coordinator
        webView = view
        find.attach(view)
        applyZoom()
        observe(view)
        soundWatch = WebAudio.watchPlaying(view) { [weak self] playing in self?.playsSound = playing }
        guard given == nil else { return }
        if let history = savedHistory {
            view.interactionState = history as NSData
            savedHistory = nil
        }
        if view.url == nil, let url { view.load(URLRequest(url: url)) }
        if url == nil, view.url == nil { wantsAddress = true }
    }

    func observe(_ view: WKWebView) {
        observations = [
            view.observe(\.title, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.changed(title: view.title) }
            },
            view.observe(\.url, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.changed(url: view.url) }
            },
            view.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.progress = view.isLoading ? view.estimatedProgress : nil }
            },
            view.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated {
                    self?.isLoading = view.isLoading
                    if !view.isLoading {
                        self?.progress = nil
                        self?.refreshFavicon()
                    }
                }
            },
            view.observe(\.canGoBack, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.canGoBack = view.canGoBack }
            },
            view.observe(\.canGoForward, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.canGoForward = view.canGoForward }
            },
            view.observe(\.cameraCaptureState, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.captureChanged(view) }
            },
            view.observe(\.microphoneCaptureState, options: [.new]) { [weak self] view, _ in
                MainActor.assumeIsolated { self?.captureChanged(view) }
            }, observePageColor(view)
        ]
    }

    func changed(title: String?) {
        guard let title else { return }
        if let address = webView?.url?.absoluteString { history?.retitle(address, title: title) }
        guard title != pageTitle else { return }
        pageTitle = title
        onChange()
    }

    func changed(url new: URL?) {
        guard let new, new != url else { return }
        let otherSite = new.host() != url?.host()
        url = new
        if otherSite { siteChanged() }
        onChange()
    }
}
