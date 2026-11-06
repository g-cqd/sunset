internal import AemiKernel

/// The OSC sequences that reach outside the screen, under the policy of ADR-0010: the clipboard (52), the working directory (7, 1337), prompt marks (133,
/// 1337) and, in `Screen+OSCNotify.swift`, notifications and progress.
extension Screen {
    static let clipboardDecodeOptions: Base64.Options = {
        var options = Base64.Options.strict
        options.maximumDecodedSize = 1 << 20
        options.errorReporting = .uniform
        return options
    }()

    mutating func hostOSC(_ code: Int, from payload: Int) {
        switch code {
            case 7: workingDirectory(fromURI: oscBuffer[min(payload, oscBuffer.count)...])
            case 9: notificationOrProgress(from: payload)
            case 52: clipboard(from: payload)
            case 99: kittyNotification(from: payload)
            case 133: promptMark(from: payload)
            case 777: terminalNotifierNotification(from: payload)
            case 1337: iTerm(from: payload)
            default: break
        }
    }

    // MARK: Clipboard (52)

    /// `52 ; targets ; data`. Only a write is acted on; a read (`?`) is denied and not answered, not even with an empty reply.
    private mutating func clipboard(from start: Int) {
        var index = start
        guard let targets = nextField(&index), index <= oscBuffer.count else { return }
        let data = index ..< oscBuffer.count
        let wanted = targets.isEmpty || oscBuffer[targets].contains { $0 == 0x63 || $0 == 0x70 || $0 == 0x73 }
        guard wanted, !data.isEmpty, !(data.count == 1 && oscBuffer[data.lowerBound] == 0x3F) else { return }
        guard let bytes = try? Base64.decode(oscBuffer[data], options: Self.clipboardDecodeOptions), !bytes.isEmpty,
            let text = String(validating: bytes, as: UTF8.self)
        else { return }
        host.post(.clipboardWrite(text))
    }

    // MARK: Working directory (7, 1337 CurrentDir)

    /// `file://host/path`, percent-encoded. Refused unless it is an absolute path of valid UTF-8 with no control characters.
    private mutating func workingDirectory(fromURI uri: ArraySlice<UInt8>) {
        let prefix = Array("file://".utf8)
        guard uri.count > prefix.count, uri.prefix(prefix.count).elementsEqual(prefix) else { return }
        let rest = uri.dropFirst(prefix.count)
        guard let slash = rest.firstIndex(of: 0x2F), let hostName = decodedText(rest[rest.startIndex ..< slash]),
            let path = decodedText(rest[slash...]), path.hasPrefix("/")
        else { return }
        host.workingDirectory = WorkingDirectory(host: hostName, path: path)
    }

    /// Percent-decodes into text; nil for a bad escape, invalid UTF-8 or any control character.
    private func decodedText(_ bytes: ArraySlice<UInt8>) -> String? {
        var decoded: [UInt8] = []
        var index = bytes.startIndex
        while index < bytes.endIndex {
            var byte = bytes[index]
            if byte == 0x25 {
                guard index + 2 < bytes.endIndex, let high = hexValue(bytes[index + 1]),
                    let low = hexValue(bytes[index + 2])
                else { return nil }
                byte = UInt8(high << 4 | low)
                index += 2
            }
            index += 1
            decoded.append(byte)
        }
        guard let text = String(validating: decoded, as: UTF8.self), !hasControl(text) else { return nil }
        return text
    }

    private func hasControl(_ text: String) -> Bool {
        text.unicodeScalars.contains { $0.properties.generalCategory == .control }
    }

    private func hexValue(_ byte: UInt8) -> Int? {
        switch byte {
            case 0x30 ... 0x39: Int(byte - 0x30)
            case 0x41 ... 0x46: Int(byte - 0x41 + 10)
            case 0x61 ... 0x66: Int(byte - 0x61 + 10)
            default: nil
        }
    }

    // MARK: Prompt marks (133, 1337 SetMark)

    /// `133 ; A|B|C|D [; status] [; options]`. Marks are not recorded on the alternate screen (full-screen programs have no prompts).
    private mutating func promptMark(from start: Int) {
        guard start < oscBuffer.count, !isAlternate else { return }
        let kind: PromptMark.Kind
        switch oscBuffer[start] {
            case 0x41: kind = .promptStart
            case 0x42: kind = .commandStart
            case 0x43: kind = .outputStart
            case 0x44: kind = .commandEnd
            default: return
        }
        var index = start + 1
        guard index == oscBuffer.count || oscBuffer[index] == 0x3B else { return }
        var status: Int?
        if kind == .commandEnd, index < oscBuffer.count {
            index += 1
            if let field = nextField(&index), let value = number(field), value <= 255 { status = value }
        }
        host.addMark(PromptMark(kind: kind, stableLine: cursorStableLine, exitStatus: status))
    }

    // MARK: iTerm2 (1337): only SetMark and CurrentDir

    private mutating func iTerm(from start: Int) {
        let rest = oscBuffer[min(start, oscBuffer.count)...]
        if rest.elementsEqual(Array("SetMark".utf8)) {
            guard !isAlternate else { return }
            host.addMark(PromptMark(kind: .promptStart, stableLine: cursorStableLine))
            return
        }
        let key = Array("CurrentDir=".utf8)
        guard rest.count > key.count, rest.prefix(key.count).elementsEqual(key) else { return }
        let path = rest.dropFirst(key.count)
        guard path.first == 0x2F, let text = String(validating: Array(path), as: UTF8.self), !hasControl(text) else {
            return
        }
        host.workingDirectory = WorkingDirectory(host: "", path: text)
    }
}
