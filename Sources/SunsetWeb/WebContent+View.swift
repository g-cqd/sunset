import AppKit
import SunsetPrivate
import WebKit

/// The page's view: made the first time the page is shown, with what Sunset sets on every page, and watched for what the page says of
/// itself (its title, address, progress).
extension WebContent {
    func makeWebView(configuration given: WKWebViewConfiguration?) {
        let configuration = given ?? WKWebViewConfiguration()
        if given == nil {
            // A private page's own; else its profile's; else the one there always was (the first profile's).
            configuration.websiteDataStore =
                settings.privacy.map(PrivateStores.store(for:))
                ?? settings.profile.map { WKWebsiteDataStore(forIdentifier: $0) } ?? .default()
        }
        // Through the app's proxy, if there is one (W-f).
        // Its profile's proxy (roadmap 0050), else the app's.
        if let proxy = settings.proxy {
            proxy.apply(to: configuration.websiteDataStore)
        } else {
            WebProxy.applyCurrent(to: configuration.websiteDataStore)
        }
        configuration.applicationNameForUserAgent = settings.applicationName
        if given == nil {
            configuration.webExtensionController = ExtensionHosts.shared.host(for: settings.profile)?.controller
        }
        installWatches(on: configuration)
        SignInWatch.install(on: configuration, privately: isPrivate, profile: settings.profile)
        if !isPrivate { shareWrapper = ShareWrapper.install(on: configuration, for: self) }
        if settings.agentScripts { AgentScript.install(on: configuration) }
        WebDeveloperExtras.set(settings.developer, on: configuration.preferences)
        WebPermissionHooks.enable(on: configuration.preferences)
        WebFrameRate.set(fullRate: settings.fullFrameRate, on: configuration.preferences)
        configuration.defaultWebpagePreferences = WebProtection.preferences(for: settings)
        WebAttribution.turnOff(on: configuration.preferences)
        SafariParity.turnOn(on: configuration.preferences)
        if settings.mediaDevices { WebFeature.set("MediaDevicesEnabled", enabled: true, on: configuration.preferences) }
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
        openAsExtensionTab(in: configuration.webExtensionController)
        // Ads and trackers blocked (W-c), unless paused for the site.
        ContentBlocker.shared.attach(view, host: url?.host(), blocks: settings.blocking, profile: settings.profile)
        view.customUserAgent = agent(for: url).userAgent
        view.isInspectable = settings.developer
        view.allowsBackForwardNavigationGestures = true
        view.allowsMagnification = true
        view.offersPrivateTab = !isPrivate
        view.onFocus = { [weak self] in self?.onFocusRequest() }
        wireSearch(view)
        let coordinator = WebCoordinator(content: self)
        view.navigationDelegate = coordinator
        view.uiDelegate = coordinator
        self.coordinator = coordinator
        webView = view
        isUnloaded = false
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
                        // Pictured once (another window shows its picture, its tab's card): pictured again as it is now
                        // (roadmap 0036 D).
                        if self?.picture != nil { self?.takePicture() }
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
            }, observePageColor(view), observeThemeColor(view)
        ]
    }

    func changed(title: String?) {
        guard let title else { return }
        if let address = webView?.url?.absoluteString { history?.retitle(address, title: title) }
        guard title != pageTitle else { return }
        pageTitle = title
        onChange()
        // Pictured once: pictured again as it changes without loading (a chat's count), once a second at most (roadmap 0037 A).
        if picture != nil, !isLoading {
            let now = ProcessInfo.processInfo.systemUptime
            if lastTitlePicture.map({ now - $0 >= 1 || now < $0 }) ?? true {
                lastTitlePicture = now
                takePicture()
            }
        }
    }

    /// The page's text changed and its title did not (`TextWatch`): pictured once, it is pictured again, as for a new title,
    /// at most every two seconds (roadmap 0042 D).
    func textChanged(at now: Double) {
        guard picture != nil, !isLoading else { return }
        if let last = lastTextPicture, now >= last, now - last < Double(TextWatch.interval) / 1000 { return }
        lastTextPicture = now
        takePicture()
    }

    func changed(url new: URL?) {
        guard let new, new != url else { return }
        let otherSite = new.host() != url?.host()
        url = new
        if otherSite { siteChanged() }
        onChange()
    }

    /// The text menu's Search the Web: Sunset's engine, the page's selection, a page the page opened.
    private func wireSearch(_ view: SunsetWebView) {
        view.runtime = runtime
        view.searchEngine = { [weak self] in self?.settings.engine }
        view.onSearch = { [weak self] address in
            guard let self else { return }
            onOpen(WebContent(url: address, settings: settings), .opened)
        }
        view.searchWords = { [weak view] in
            try? await view?.evaluateJavaScript("String(getSelection())") as? String
        }
    }

    /// Its profile's extensions see it as a tab (roadmap 0109 B; a private page only those allowed there: each context's own
    /// access to private data).
    private func openAsExtensionTab(in controller: WKWebExtensionController?) {
        guard let controller else { return }
        let tab = ExtensionTab(self)
        extensionTab = tab
        controller.didOpenTab(tab)
    }

    /// What reads the page for Sunset: the link under the pointer, its notifications, its icon, its text.
    private func installWatches(on configuration: WKWebViewConfiguration) {
        LinkHover.install(on: configuration, for: self)
        WebNotifications.install(on: configuration, for: self)
        IconWatch.install(on: configuration, for: self)
        TextWatch.install(on: configuration, for: self)
    }
}
