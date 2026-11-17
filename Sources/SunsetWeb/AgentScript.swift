import WebKit

/// The second rung of appearing as another browser (R5; ADR-0052): what a page's scripts read first to tell a browser,
/// set to what the browser named in the User-Agent says. It runs before the page's own scripts, in every frame, and
/// decides by `navigator.userAgent` alone, so it always agrees with the header; with Safari's (Sunset as it is) it does
/// nothing.
///
/// Set for Chrome and Edge: `navigator.vendor` ("Google Inc."), `navigator.userAgentData` (the brands, not mobile,
/// macOS, and the fuller values when asked), and a `window.chrome` object with the members scripts look for. For
/// Firefox: an empty vendor, `productSub`, `oscpu`, `buildID`, and no `window.chrome`. Nothing else: what the engine can
/// and cannot do, how it lays out and draws, and the connection, are WebKit's, and a script that looks further can tell.
enum AgentScript {
    static func install(on configuration: WKWebViewConfiguration) {
        configuration.userContentController.addUserScript(
            WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .page)
        )
    }

    static let source = """
        (() => {
          const ua = navigator.userAgent;
          const edge = (ua.match(/ Edg\\/(\\d+)/) || [])[1];
          const chrome = (ua.match(/ Chrome\\/(\\d+)/) || [])[1];
          const firefox = / Firefox\\//.test(ua);
          if (!chrome && !firefox) return;
          const set = (name, value) => {
            try { Object.defineProperty(Navigator.prototype, name, { get: () => value, configurable: true, enumerable: true }); }
            catch (error) {}
          };
          if (firefox) {
            set('vendor', ''); set('productSub', '20100101'); set('oscpu', 'Intel Mac OS X 10.15');
            set('buildID', '20181001000000');
            return;
          }
          const brands = edge
            ? [{ brand: 'Chromium', version: chrome }, { brand: 'Microsoft Edge', version: edge }, { brand: 'Not?A_Brand', version: '99' }]
            : [{ brand: 'Chromium', version: chrome }, { brand: 'Google Chrome', version: chrome }, { brand: 'Not?A_Brand', version: '99' }];
          const low = { brands, mobile: false, platform: 'macOS' };
          const full = Object.assign({}, low, {
            architecture: 'arm', bitness: '64', model: '', platformVersion: '15.0.0', wow64: false,
            uaFullVersion: (edge || chrome) + '.0.0.0',
            fullVersionList: brands.map(b => ({ brand: b.brand, version: b.version + '.0.0.0' }))
          });
          set('vendor', 'Google Inc.');
          set('userAgentData', Object.assign({}, low, {
            getHighEntropyValues: hints => Promise.resolve(Object.assign({}, low,
              Object.fromEntries((hints || []).filter(h => h in full).map(h => [h, full[h]])))),
            toJSON: () => low
          }));
          if (!window.chrome) {
            try {
              Object.defineProperty(window, 'chrome', { configurable: true, writable: true, value: {
                app: { isInstalled: false }, runtime: {}, csi: () => ({}), loadTimes: () => ({}) } });
            } catch (error) {}
          }
        })();
        """
}
