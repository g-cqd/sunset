extension Screen: VTSink {
    public mutating func printASCII(_ run: Span<UInt8>) {
        if modes.insert {
            for index in run.indices { putASCII(run[index]) }
        } else {
            putASCIIRun(run)
        }
    }

    public mutating func print(_ scalar: Unicode.Scalar) { putScalar(scalar) }

    /// A carriage return, the control every line has, is done where it is met; the others go through `executeOther` (a call that saves a dozen
    /// registers cost five times what the return itself does).
    @inline(__always) public mutating func execute(_ control: UInt8) {
        joinable = false
        if control == 0x0D {
            carriageReturn()
        } else {
            executeOther(control)
        }
    }

    @inline(never) mutating func executeOther(_ control: UInt8) {
        switch control {
            case 0x07: bellCount &+= 1
            case 0x08: backspace()
            case 0x0E: shifted = true
            case 0x0F: shifted = false
            case 0x09: tab(forward: 1)
            case 0x0A, 0x0B, 0x0C: lineFeed()
            case 0x0D: carriageReturn()
            case 0x84: lineFeed()
            case 0x85:
                carriageReturn()
                lineFeed()
            case 0x88: setTabStop()
            case 0x8D: reverseIndex()
            default: break
        }
    }

    public mutating func escape(_ intermediates: Intermediates, final: UInt8) {
        joinable = false
        if intermediates.count == 1, intermediates.first == 0x28 || intermediates.first == 0x29 {
            if intermediates.first == 0x28 {
                charsets.g0 = Charset(designator: final)
            } else {
                charsets.g1 = Charset(designator: final)
            }
            return
        }
        if intermediates.count == 1, intermediates.first == 0x23 {
            if final == 0x38 { alignmentTest() }
            return
        }
        guard intermediates.count == 0 else { return }
        switch final {
            case 0x37: saveCursor()
            case 0x38: restoreCursor()
            case 0x3D: modes.applicationKeypad = true
            case 0x3E: modes.applicationKeypad = false
            case 0x44: lineFeed()
            case 0x45:
                carriageReturn()
                lineFeed()
            case 0x48: setTabStop()
            case 0x4D: reverseIndex()
            case 0x63: fullReset()
            default: break
        }
    }

    public mutating func csi(_ parameters: Parameters, marker: UInt8, intermediates: Intermediates, final: UInt8) {
        joinable = false
        switch intermediates.count {
            case 0:
                switch marker {
                    case 0: csiStandard(parameters, final: final)
                    case 0x3F: csiPrivate(parameters, final: final)
                    case 0x3E: csiGreater(parameters, final: final)
                    case 0x3C: if final == 0x75 { keyboardPop(parameters.value(0, default: 1)) }
                    case 0x3D: if final == 0x75 { keyboardSet(parameters[0], mode: parameters.value(1, default: 1)) }
                    default: break
                }
            case 1: csiIntermediate(parameters, marker: marker, intermediate: intermediates.first, final: final)
            default: break
        }
    }

    /// `CSI > ...`: secondary attributes, version, keyboard push.
    private mutating func csiGreater(_ parameters: Parameters, final: UInt8) {
        switch final {
            case 0x63: if parameters[0] == 0 { reportSecondaryDeviceAttributes() }
            case 0x71: if parameters[0] == 0 { reportVersion() }
            case 0x75: keyboardPush(parameters[0])
            default: break
        }
    }

    /// Sequences with one intermediate byte: `$p` DECRQM, `SP q` DECSCUSR, `! p` DECSTR.
    private mutating func csiIntermediate(_ parameters: Parameters, marker: UInt8, intermediate: UInt8, final: UInt8) {
        switch (intermediate, final) {
            case (0x24, 0x70) where marker == 0 || marker == 0x3F:
                reportMode(parameters[0], private: marker == 0x3F)
            case (0x20, 0x71) where marker == 0: setCursorStyle(parameters[0])
            case (0x21, 0x70) where marker == 0: softReset()
            default: break
        }
    }

    private mutating func csiPrivate(_ parameters: Parameters, final: UInt8) {
        if final == 0x6E {
            deviceStatus(parameters[0], private: true)
            return
        }
        if final == 0x75 {
            keyboardQuery()
            return
        }
        guard final == 0x68 || final == 0x6C else { return }
        for index in 0 ..< parameters.count where !parameters.isSubParameter(index) {
            setPrivateMode(parameters[index], enabled: final == 0x68)
        }
    }

    private mutating func csiStandard(_ parameters: Parameters, final: UInt8) {
        let n = parameters.value(0, default: 1)
        switch final {
            case 0x40: insertCells(n)
            case 0x41: moveUp(n)
            case 0x42, 0x65: moveDown(n)
            case 0x43, 0x61: moveRight(n)
            case 0x44: moveLeft(n)
            case 0x45:
                moveDown(n)
                carriageReturn()
            case 0x46:
                moveUp(n)
                carriageReturn()
            case 0x47, 0x60:
                pendingWrap = false
                column = min(columns - 1, n - 1)
            case 0x48, 0x66: moveTo(row: n, column: parameters.value(1, default: 1))
            case 0x49: tab(forward: n)
            case 0x4A: eraseInDisplay(parameters[0])
            case 0x4B: eraseInLine(parameters[0])
            case 0x4C: insertLines(n)
            case 0x4D: deleteLines(n)
            case 0x50: deleteCells(n)
            case 0x53: scrollUp(from: top, to: bottom, by: n)
            case 0x54: scrollDown(from: top, to: bottom, by: n)
            case 0x58: eraseCharacters(n)
            case 0x5A: tab(backward: n)
            case 0x62: repeatLast(n)
            case 0x64:
                pendingWrap = false
                setRow(n - 1)
            case 0x67: clearTabStops(all: parameters[0] == 3)
            case 0x68, 0x6C:
                for index in 0 ..< parameters.count { setANSIMode(parameters[index], enabled: final == 0x68) }
            case 0x6D: applySGR(parameters)
            case 0x72: setScrollRegion(top: parameters[0], bottom: parameters[1])
            case 0x73: saveCursor()
            case 0x6E: deviceStatus(parameters[0], private: false)
            case 0x63: if parameters[0] == 0 { reportDeviceAttributes() }
            case 0x74: windowOperation(parameters)
            case 0x75: restoreCursor()
            default: break
        }
    }

    public mutating func stringStart(
        _ kind: StringKind,
        parameters: Parameters,
        marker: UInt8,
        intermediates: Intermediates,
        final: UInt8
    ) {
        joinable = false
        oscStart(kind)
    }
    public mutating func stringBytes(_ bytes: Span<UInt8>) { oscAppend(bytes) }
    public mutating func stringEnd(completed: Bool, terminator: StringTerminator) {
        oscEnd(completed: completed, terminator: terminator)
    }
}
