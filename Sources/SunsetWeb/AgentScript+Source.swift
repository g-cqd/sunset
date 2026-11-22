/// The script itself (ADR-0052, ADR-0074). Chrome's values were read from Chrome Canary 160 on 2026-11-18.
extension AgentScript {
    // swiftlint:disable function_body_length - one script, read as one
    package static func make(
        chrome: String,
        edge: String,
        platformVersion: String,
        architecture: String,
        memory: Double
    )
        -> String
    {
        #"""
        (() => {
          const ua = navigator.userAgent;
          const edge = (ua.match(/ Edg\/(\d+)/) || [])[1];
          const chromium = (ua.match(/ Chrome\/(\d+)/) || [])[1];
          const firefox = / Firefox\//.test(ua);
          if (!chromium && !firefox) return;
          const define = Object.defineProperty;
          const owns = (object, name) => Object.prototype.hasOwnProperty.call(object, name);
          // What Sunset sets reads as the engine's own; a native function is written as the browser writes it.
          const texts = new WeakMap();
          const nativeText = name => chromium
            ? 'function ' + name + '() { [native code] }' : 'function ' + name + '() {\n    [native code]\n}';
          const fn = (name, body, length = 0) => {
            const made = { [name](...args) { return Reflect.apply(body, this, args); } }[name];
            define(made, 'length', { value: length });
            texts.set(made, nativeText(name));
            return made;
          };
          const engineText = Function.prototype.toString;
          const multiline = /^function ([^(]*)\(\) \{\n    \[native code\]\n\}$/;
          define(Function.prototype, 'toString', { writable: true, enumerable: false, configurable: true, value: fn('toString', function () {
            const own = texts.get(this);
            if (own !== undefined) return own;
            const text = Reflect.apply(engineText, this, []);
            return chromium ? text.replace(multiline, 'function $1() { [native code] }') : text;
          }) });
          const property = (target, name, read) =>
            define(target, name, { get: fn('get ' + name, read), set: undefined, enumerable: true, configurable: true });
          const operation = (target, name, body, length = 0) =>
            define(target, name, { value: fn(name, body, length), writable: true, enumerable: true, configurable: true });
          const remove = (names, ...objects) => {
            for (const object of objects) for (const name of names) {
              for (let at = object; at; at = Object.getPrototypeOf(at)) {
                if (owns(at, name)) { try { delete at[name]; } catch (error) {} break; }
              }
            }
          };
          // What only Safari has. `window.webkit`, an app's web view's, cannot be taken away (tried: it stays).
          const force = ['onwebkitmouseforcechanged', 'onwebkitmouseforcedown', 'onwebkitmouseforceup', 'onwebkitmouseforcewillbegin'];
          remove(['standalone'], navigator);
          remove(['GestureEvent', 'WebKitPoint', ...force], window);
          remove(force, HTMLElement.prototype, Document.prototype);
          // Chrome and Firefox play HLS through Media Source Extensions only: they offer no native HLS (t15).
          const canPlay = HTMLMediaElement.prototype.canPlayType;
          const hls = /^\s*application\/(vnd\.apple\.mpegurl|x-mpegurl)\s*(;|$)/i;
          define(HTMLMediaElement.prototype, 'canPlayType', { writable: true, enumerable: true, configurable: true,
            value: fn('canPlayType', function (type) { return hls.test(String(type)) ? '' : Reflect.apply(canPlay, this, [type]); }, 1) });
          if (firefox) {
            property(Navigator.prototype, 'vendor', () => '');
            property(Navigator.prototype, 'productSub', () => '20100101');
            property(Navigator.prototype, 'oscpu', () => 'Intel Mac OS X 10.15');
            property(Navigator.prototype, 'buildID', () => '20181001000000');
            return;
          }
          const brands = edge ? \#(edge) : \#(chrome);
          const copy = list => list.map(b => ({ brand: b.brand, version: b.version }));
          property(Navigator.prototype, 'vendor', () => 'Google Inc.');
          if (isSecureContext) {
            const full = {
              architecture: '\#(architecture)', bitness: '64', formFactors: ['Desktop'],
              fullVersionList: brands.map(b => ({ brand: b.brand, version: b.version + '.0.0.0' })), model: '',
              platformVersion: '\#(platformVersion)', uaFullVersion: (edge || chromium) + '.0.0.0', wow64: false
            };
            class NavigatorUAData {
              constructor() { throw new TypeError("Failed to construct 'NavigatorUAData': Illegal constructor"); }
            }
            texts.set(NavigatorUAData, nativeText('NavigatorUAData'));
            const prototype = NavigatorUAData.prototype;
            const low = () => ({ brands: Object.freeze(copy(brands)), mobile: false, platform: 'macOS' });
            property(prototype, 'brands', () => Object.freeze(copy(brands)));
            property(prototype, 'mobile', () => false);
            property(prototype, 'platform', () => 'macOS');
            operation(prototype, 'getHighEntropyValues', hints => {
              if (typeof hints !== 'object' || hints === null) {
                return Promise.reject(new TypeError("Failed to execute 'getHighEntropyValues' on 'NavigatorUAData': The provided value cannot be converted to a sequence."));
              }
              const values = low();
              for (const hint of Array.from(hints, String)) {
                if (owns(full, hint)) values[hint] = JSON.parse(JSON.stringify(full[hint]));
              }
              return Promise.resolve(Object.fromEntries(Object.keys(values).sort().map(key => [key, values[key]])));
            }, 1);
            operation(prototype, 'toJSON', () => low());
            define(prototype, Symbol.toStringTag, { value: 'NavigatorUAData', configurable: true });
            const data = Object.create(prototype);
            property(Navigator.prototype, 'userAgentData', () => data);
            define(window, 'NavigatorUAData', { value: NavigatorUAData, writable: true, enumerable: false, configurable: true });
            property(Navigator.prototype, 'deviceMemory', () => \#(memory));
          }
          if (!owns(window, 'chrome')) {
            const start = performance.timeOrigin;
            const timing = () => performance.getEntriesByType('navigation')[0] || {};
            const app = { isInstalled: false };
            app.getDetails = fn('getDetails', () => null);
            app.getIsInstalled = fn('getIsInstalled', () => false);
            app.installState = fn('installState', done => { if (typeof done === 'function') setTimeout(() => done('not_installed')); });
            app.runningState = fn('runningState', () => 'cannot_run');
            app.InstallState = { DISABLED: 'disabled', INSTALLED: 'installed', NOT_INSTALLED: 'not_installed' };
            app.RunningState = { CANNOT_RUN: 'cannot_run', READY_TO_RUN: 'ready_to_run', RUNNING: 'running' };
            // Chrome's two are nameless.
            const csi = fn('', () => {
              const t = timing();
              return { startE: Math.round(start), onloadT: t.loadEventEnd ? Math.round(start + t.loadEventEnd) : 0,
                       pageT: performance.now(), tran: 15 };
            });
            const loadTimes = fn('', () => {
              const t = timing();
              const at = ms => ms ? (start + ms) / 1000 : 0;
              const protocol = t.nextHopProtocol || 'http/1.1';
              const spdy = protocol === 'h2' || protocol === 'h3';
              return { requestTime: start / 1000, startLoadTime: start / 1000, commitLoadTime: at(t.responseStart),
                       finishDocumentLoadTime: at(t.domContentLoadedEventEnd), finishLoadTime: at(t.loadEventEnd),
                       firstPaintTime: 0, firstPaintAfterLoadTime: 0, navigationType: 'Other', wasFetchedViaSpdy: spdy,
                       wasNpnNegotiated: spdy, npnNegotiatedProtocol: spdy ? protocol : 'unknown',
                       wasAlternateProtocolAvailable: false, connectionInfo: protocol };
            });
            define(window, 'chrome', { value: { app, csi, loadTimes }, writable: true, enumerable: true, configurable: true });
          }
        })();
        """#
    }
    // swiftlint:enable function_body_length
}
