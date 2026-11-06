extension Screen {
    /// SGR: a list of attribute changes. Colours come as `38;5;n`, `38;2;r;g;b` or the colon forms `38:5:n`, `38:2::r:g:b` (and without the colour-space
    /// slot).
    mutating func applySGR(_ parameters: Parameters) {
        guard parameters.count > 0 else {
            pen = CellStyle()
            penChanged()
            return
        }
        var index = 0
        while index < parameters.count {
            let code = parameters[index]
            index += 1
            switch code {
                case 38: pen.foreground = readColor(parameters, &index) ?? pen.foreground
                case 48: pen.background = readColor(parameters, &index) ?? pen.background
                case 58: pen.underlineColor = readColor(parameters, &index) ?? pen.underlineColor
                case 4:
                    // `4:n` selects the style; a plain 4 is a single underline.
                    if index < parameters.count, parameters.isSubParameter(index) {
                        pen.underline = UnderlineStyle(rawValue: UInt8(min(parameters[index], 5))) ?? .single
                        index += 1
                    } else {
                        pen.underline = .single
                    }
                default: applySimpleSGR(code)
            }
        }
        penChanged()
    }

    private mutating func applySimpleSGR(_ code: Int) {
        switch code {
            case 0: pen = CellStyle()
            case 1: pen.attributes.insert(.bold)
            case 2: pen.attributes.insert(.faint)
            case 3: pen.attributes.insert(.italic)
            case 5, 6: pen.attributes.insert(.blink)
            case 7: pen.attributes.insert(.inverse)
            case 8: pen.attributes.insert(.invisible)
            case 9: pen.attributes.insert(.strikethrough)
            case 21: pen.underline = .double
            case 22: pen.attributes.subtract([.bold, .faint])
            case 23: pen.attributes.remove(.italic)
            case 24: pen.underline = .none
            case 25: pen.attributes.remove(.blink)
            case 27: pen.attributes.remove(.inverse)
            case 28: pen.attributes.remove(.invisible)
            case 29: pen.attributes.remove(.strikethrough)
            case 30 ... 37: pen.foreground = .indexed(UInt8(code - 30))
            case 39: pen.foreground = .default
            case 40 ... 47: pen.background = .indexed(UInt8(code - 40))
            case 49: pen.background = .default
            case 53: pen.attributes.insert(.overline)
            case 55: pen.attributes.remove(.overline)
            case 59: pen.underlineColor = .default
            case 90 ... 97: pen.foreground = .indexed(UInt8(code - 90 + 8))
            case 100 ... 107: pen.background = .indexed(UInt8(code - 100 + 8))
            default: break
        }
    }

    /// Reads the arguments of 38/48/58 starting at `index`, advancing past them. Nil when they are malformed (the arguments are still consumed).
    private func readColor(_ parameters: Parameters, _ index: inout Int) -> Color? {
        guard index < parameters.count else { return nil }
        let colon = parameters.isSubParameter(index)
        let kind = parameters[index]
        index += 1
        func byte(_ value: Int) -> UInt8 { UInt8(min(max(value, 0), 255)) }
        switch kind {
            case 5:
                guard index < parameters.count else { return nil }
                defer { index += 1 }
                return .indexed(byte(parameters[index]))
            case 2:
                // Semicolons: exactly three values follow. Colons: the sub-parameters that follow, three, or four when the first is a colour-space id.
                var count = 0
                if colon {
                    while index + count < parameters.count, parameters.isSubParameter(index + count) { count += 1 }
                } else {
                    count = min(3, parameters.count - index)
                }
                defer { index += count }
                guard count >= 3 else { return nil }
                let start = colon && count >= 4 ? index + 1 : index
                return .rgb(byte(parameters[start]), byte(parameters[start + 1]), byte(parameters[start + 2]))
            default:
                return nil
        }
    }
}
