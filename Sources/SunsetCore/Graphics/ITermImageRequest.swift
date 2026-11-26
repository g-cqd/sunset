import AemiKernel

/// iTerm2 inline image protocol (`OSC 1337 ; File=[args]:<base64>` — roadmap 0010 F): parses the arguments and base64
/// payload safely, verifies PNG header dimensions (refusing oversized or non-PNG files), and resolves display dimensions
/// in pixels & cells (`auto`, `N` cells, `Npx`, `N%`, and `preserveAspectRatio`).
struct ITermImageRequest: Sendable, Equatable {
    enum Dimension: Sendable, Equatable {
        case auto
        case cells(Int)
        case pixels(Int)
        case percent(Int)
    }

    let width: Dimension
    let height: Dimension
    let preserveAspectRatio: Bool
    let data: [UInt8]
    let pixelWidth: Int
    let pixelHeight: Int

    /// Parses the payload after `File=` in `OSC 1337 ; File=<args>:<base64>`. Returns nil unless `inline=1` is set, the
    /// base64 decodes cleanly within `maxBytes`, and the payload is a valid PNG within `TerminalGraphics.sideLimit`.
    static func parse(_ bytes: ArraySlice<UInt8>, maxBytes: Int) -> Self? {
        guard let colon = bytes.firstIndex(of: UInt8(ascii: ":")) else { return nil }
        let args = bytes[..<colon]
        let payload = bytes[bytes.index(after: colon)...]
        guard !payload.isEmpty else { return nil }

        var inline = false
        var width = Dimension.auto
        var height = Dimension.auto
        var preserveAspectRatio = true

        for pair in args.split(separator: UInt8(ascii: ";"), omittingEmptySubsequences: true) {
            guard let eq = pair.firstIndex(of: UInt8(ascii: "=")) else { continue }
            let key = String(decoding: pair[..<eq], as: UTF8.self)
            let val = String(decoding: pair[pair.index(after: eq)...], as: UTF8.self)
            switch key {
                case "inline": inline = (val == "1")
                case "width": width = parseDimension(val)
                case "height": height = parseDimension(val)
                case "preserveAspectRatio": preserveAspectRatio = (val != "0")
                default: break
            }
        }
        guard inline else { return nil }
        // Quick upper-bound check before allocating base64 output.
        let estimated = (payload.count / 4) * 3 + 3
        guard estimated <= maxBytes + 64 else { return nil }
        guard let decoded = Base64.decode(payload), !decoded.isEmpty, decoded.count <= maxBytes else { return nil }
        guard let pngSize = PNGHeader.size(decoded),
            (1 ... TerminalGraphics.sideLimit).contains(pngSize.width),
            (1 ... TerminalGraphics.sideLimit).contains(pngSize.height)
        else { return nil }
        return Self(
            width: width,
            height: height,
            preserveAspectRatio: preserveAspectRatio,
            data: decoded,
            pixelWidth: pngSize.width,
            pixelHeight: pngSize.height
        )
    }

    /// Resolves display size in pixels and cells for the given grid & cell dimensions.
    func resolvedSize(
        columns screenColumns: Int,
        rows screenRows: Int,
        cellWidth rawCellW: Int,
        cellHeight rawCellH: Int
    ) -> (cells: (columns: Int, rows: Int), pixels: (width: Int, height: Int)) {
        let cellW = max(rawCellW, 1)
        let cellH = max(rawCellH, 1)
        let maxW = max(screenColumns * cellW, cellW)
        let maxH = max(screenRows * cellH, cellH)
        let limit = TerminalGraphics.sideLimit

        let explicitW = Self.pixels(for: width, cell: cellW, screen: maxW, limit: limit)
        let explicitH = Self.pixels(for: height, cell: cellH, screen: maxH, limit: limit)

        let (drawW, drawH): (Int, Int)
        switch (explicitW, explicitH) {
            case (let w?, let h?) where preserveAspectRatio:
                let scale = min(Double(w) / Double(pixelWidth), Double(h) / Double(pixelHeight))
                drawW = max(min(Int((Double(pixelWidth) * scale).rounded()), limit), 1)
                drawH = max(min(Int((Double(pixelHeight) * scale).rounded()), limit), 1)
            case (let w?, let h?):
                (drawW, drawH) = (w, h)
            case (let w?, nil):
                drawW = w
                drawH = max(min((pixelHeight * w + pixelWidth / 2) / pixelWidth, limit), 1)
            case (nil, let h?):
                drawH = h
                drawW = max(min((pixelWidth * h + pixelHeight / 2) / pixelHeight, limit), 1)
            case (nil, nil):
                (drawW, drawH) = (min(pixelWidth, limit), min(pixelHeight, limit))
        }
        let cols = min(max((drawW + cellW - 1) / cellW, 1), limit)
        let rows = min(max((drawH + cellH - 1) / cellH, 1), limit)
        return ((cols, rows), (drawW, drawH))
    }

    private static func pixels(for dim: Dimension, cell: Int, screen: Int, limit: Int) -> Int? {
        switch dim {
            case .auto: nil
            case .cells(let n): min(max(n * cell, 1), limit)
            case .pixels(let n): min(max(n, 1), limit)
            case .percent(let p): min(max((screen * p) / 100, 1), limit)
        }
    }

    private static func parseDimension(_ raw: String) -> Dimension {
        if raw.isEmpty || raw == "auto" { return .auto }
        if raw.hasSuffix("px"), let n = Int(raw.dropLast(2)), n > 0 {
            return .pixels(min(n, TerminalGraphics.sideLimit))
        }
        if raw.hasSuffix("%"), let n = Int(raw.dropLast()), n > 0 { return .percent(min(n, 1000)) }
        if let n = Int(raw), n > 0 { return .cells(min(n, TerminalGraphics.sideLimit)) }
        return .auto
    }
}
