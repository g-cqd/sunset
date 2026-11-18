import AppKit
import ImageIO
import UniformTypeIdentifiers
import WebKit

final class Frames: NSObject, WKURLSchemeHandler {
    var latest = Data()
    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        guard let url = task.request.url,
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "image/jpeg", "Access-Control-Allow-Origin": "*"]
            )
        else { return }
        task.didReceive(response)
        task.didReceive(latest)
        task.didFinish()
    }
    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}
}

@MainActor final class Loader: NSObject, WKNavigationDelegate {
    var c: CheckedContinuation<Void, Never>?
    func webView(_ w: WKWebView, didFinish n: WKNavigation?) {
        c?.resume()
        c = nil
    }

    func load(_ v: WKWebView, _ s: String) async {
        guard let url = URL(string: s) else { return }
        await withCheckedContinuation { continuation in
            c = continuation
            v.load(URLRequest(url: url))
        }
    }
}

func jpeg(_ image: NSImage, quality: Double) -> Data {
    guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return Data() }
    let out = NSMutableData()
    guard let d = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil) else {
        return Data()
    }
    CGImageDestinationAddImage(d, cg, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    CGImageDestinationFinalize(d)
    return out as Data
}

func pct(_ xs: [Double]) -> String {
    let s = xs.sorted()
    func p(_ q: Double) -> Double { s[min(s.count - 1, Int(Double(s.count) * q))] }
    return String(format: "p50 %.1f  p90 %.1f  p99 %.1f ms  (n=%d)", p(0.5), p(0.9), p(0.99), s.count)
}

@MainActor func run() async {
    let size = CGSize(width: 1920, height: 1080)
    let window = NSWindow(
        contentRect: CGRect(x: -6000, y: -6000, width: 1920, height: 2200),
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.orderBack(nil)
    let source = WKWebView(frame: CGRect(origin: .zero, size: size))
    let frames = Frames()
    let config = WKWebViewConfiguration()
    config.setURLSchemeHandler(frames, forURLScheme: "sunsetframe")
    let sink = WKWebView(frame: CGRect(x: 0, y: 1100, width: 1920, height: 1080), configuration: config)
    window.contentView?.addSubview(source)
    window.contentView?.addSubview(sink)
    let l = Loader()
    source.navigationDelegate = l
    sink.navigationDelegate = l
    await l.load(source, "http://127.0.0.1:8766/anim.html")
    await l.load(sink, "http://127.0.0.1:8766/sink.html")
    let snap = WKSnapshotConfiguration()
    snap.snapshotWidth = 1920
    var shot: [Double] = []
    var enc: [Double] = []
    var deliverA: [Double] = []
    var deliverB: [Double] = []
    var bytes: [Double] = []
    let n = 120
    // Route A: base64 through callAsyncJavaScript.
    let startA = Date()
    for _ in 0 ..< n {
        let t0 = Date()
        guard let img = try? await source.takeSnapshot(configuration: snap) else {
            print("no snapshot")
            exit(1)
        }
        let t1 = Date()
        let data = jpeg(img, quality: 0.6)
        let t2 = Date()
        _ = try? await sink.callAsyncJavaScript(
            "return await drawB64(b)",
            arguments: ["b": data.base64EncodedString()],
            contentWorld: .page
        )
        let t3 = Date()
        shot.append(t1.timeIntervalSince(t0) * 1000)
        enc.append(t2.timeIntervalSince(t1) * 1000)
        deliverA.append(t3.timeIntervalSince(t2) * 1000)
        bytes.append(Double(data.count))
    }
    let fpsA = Double(n) / Date().timeIntervalSince(startA)
    let (lag, fpsP) = await pipelined(source: source, sink: sink, snap: snap, count: n)
    let fpsB = fpsP
    deliverB = lag
    print("snapshot 1920w:  ", pct(shot))
    print("jpeg q0.6:       ", pct(enc), String(format: " size p50 %.0f KB", bytes.sorted()[n / 2] / 1024))
    print("deliver A base64:", pct(deliverA), String(format: "  whole loop %.1f fps", fpsA))
    print("pipelined, snapshot to drawn:", pct(deliverB), String(format: "  %.1f fps", fpsB))
    await checkWebRTC(sink)
    exit(0)
}
/// The next snapshot and encoding while the frame before is delivered: snapshot to drawn, and the frames a second.
@MainActor func pipelined(source: WKWebView, sink: WKWebView, snap: WKSnapshotConfiguration, count n: Int) async -> (
    [Double], Double
) {
    let startP = Date()
    var lag: [Double] = []
    var pending: Task<Void, Never>?
    for _ in 0 ..< n {
        let t0 = Date()
        guard let img = try? await source.takeSnapshot(configuration: snap) else { exit(1) }
        let data = jpeg(img, quality: 0.6)
        await pending?.value
        let b64 = data.base64EncodedString()
        pending = Task { @MainActor in
            _ = try? await sink.callAsyncJavaScript(
                "return await drawB64(b)",
                arguments: ["b": b64],
                contentWorld: .page
            )
            lag.append(Date().timeIntervalSince(t0) * 1000)
        }
    }
    await pending?.value
    let fpsP = Double(n) / Date().timeIntervalSince(startP)
    return (lag, fpsP)
}

/// Whether WebRTC sends the canvas's stream, and a wrapped `getDisplayMedia` returns it.
@MainActor func checkWebRTC(_ sink: WKWebView) async {
    let rtc = try? await sink.callAsyncJavaScript(
        """
        const pc = new RTCPeerConnection(); const t = window.stream.getVideoTracks()[0];
        pc.addTrack(t, window.stream); const o = await pc.createOffer(); await pc.setLocalDescription(o);
        const real = navigator.mediaDevices.getDisplayMedia;
        navigator.mediaDevices.getDisplayMedia = async () => window.stream;
        const got = await navigator.mediaDevices.getDisplayMedia({video:true});
        return [pc.getSenders().length, o.sdp.includes('m=video'), got === window.stream, typeof real].join(' ')
        """,
        arguments: [:],
        contentWorld: .page
    )
    print("WebRTC sender, video offer, wrapped getDisplayMedia:", String(describing: rtc))
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
Task { @MainActor in await run() }
app.run()
