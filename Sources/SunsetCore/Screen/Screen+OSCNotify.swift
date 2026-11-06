internal import AemiKernel

/// Notifications (OSC 9, 777, 99) and progress (OSC 9;4), under the policy of ADR-0010: sanitised, bounded, no replies, nothing taken from the sequence but
/// plain text.
extension Screen {
    static let titleLimit = 256
    static let bodyLimit = 1024

    /// The text of `bytes` without control characters or bidirectional overrides, cut to at most `limit` bytes at a character boundary.
    func notificationText(_ bytes: ArraySlice<UInt8>, limit: Int) -> String {
        var scalars = String.UnicodeScalarView()
        var size = 0
        for scalar in String(decoding: bytes, as: UTF8.self).unicodeScalars {
            let value = scalar.value
            if scalar.properties.generalCategory == .control || (0x202A ... 0x202E).contains(value)
                || (0x2066 ... 0x2069).contains(value)
            {
                continue
            }
            let width = String(scalar).utf8.count
            guard size + width <= limit else { break }
            scalars.append(scalar)
            size += width
        }
        return String(scalars)
    }

    private mutating func notify(title: String, body: String) {
        guard !title.isEmpty || !body.isEmpty else { return }
        host.post(.notification(title: title, body: body))
    }

    // MARK: OSC 9: a message, or ConEmu's commands (only 4, progress, is acted on)

    mutating func notificationOrProgress(from start: Int) {
        let text = oscBuffer[min(start, oscBuffer.count)...]
        if let separator = text.firstIndex(of: 0x3B), separator > text.startIndex,
            text[text.startIndex ..< separator].allSatisfy({ $0 >= 0x30 && $0 <= 0x39 })
        {
            if separator == text.startIndex + 1, text[text.startIndex] == 0x34 { progress(from: separator + 1) }
            return
        }
        notify(title: "", body: notificationText(text, limit: Self.bodyLimit))
    }

    private mutating func progress(from start: Int) {
        var index = start
        guard let stateField = nextField(&index), let state = number(stateField) else { return }
        var percent = 0
        if let field = nextField(&index), !field.isEmpty {
            guard let value = number(field), value <= 100 else { return }
            percent = value
        }
        switch state {
            case 0: host.progress = .hidden
            case 1: host.progress = .normal(percent: percent)
            case 2: host.progress = .error(percent: percent)
            case 3: host.progress = .indeterminate
            case 4: host.progress = .paused(percent: percent)
            default: break
        }
    }

    // MARK: OSC 777;notify;title;body

    mutating func terminalNotifierNotification(from start: Int) {
        var index = start
        guard let command = nextField(&index), oscBuffer[command].elementsEqual(Array("notify".utf8)),
            let title = nextField(&index)
        else { return }
        let body = index <= oscBuffer.count ? oscBuffer[index...] : []
        notify(
            title: notificationText(oscBuffer[title], limit: Self.titleLimit),
            body: notificationText(body, limit: Self.bodyLimit)
        )
    }

    // MARK: OSC 99 (kitty): `metadata ; payload`, pieces joined by id

    mutating func kittyNotification(from start: Int) {
        var index = start
        guard let metadata = nextField(&index) else { return }
        let payload = index <= oscBuffer.count ? oscBuffer[index...] : []
        var id = ""
        var done = true
        var kind = "title"
        var encoded = false
        for pair in oscBuffer[metadata].split(separator: 0x3A) {
            guard let equals = pair.firstIndex(of: 0x3D) else { continue }
            let value = pair[(equals + 1)...]
            switch String(decoding: pair[pair.startIndex ..< equals], as: UTF8.self) {
                case "i": id = notificationText(value, limit: 64)
                case "d": done = !value.elementsEqual([0x30])
                case "p": kind = String(decoding: value, as: UTF8.self)
                case "e": encoded = value.elementsEqual([0x31])
                default: break
            }
        }
        guard kind == "title" || kind == "body" else { return }
        var bytes = payload
        if encoded {
            guard let decoded = try? Base64.decode(payload, options: Self.clipboardDecodeOptions) else { return }
            bytes = decoded[...]
        }
        let text = notificationText(bytes, limit: kind == "title" ? Self.titleLimit : Self.bodyLimit)
        var current = host.pendingNotification.flatMap { $0.id == id ? $0 : nil } ?? (id: id, title: "", body: "")
        if kind == "title" { current.title = text } else { current.body = text }
        if done {
            host.pendingNotification = nil
            notify(title: current.title, body: current.body)
        } else {
            host.pendingNotification = current
        }
    }
}
