import Foundation

/// `{"pane": "<uuid>"}` for a pane, `{"axis": "horizontal", "ratio": 0.5, "first": …, "second": …}` for a split.
extension SplitLayout: Codable {
    private enum Key: String, CodingKey { case pane, axis, ratio, first, second }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        if let id = try container.decodeIfPresent(PaneID.self, forKey: .pane) {
            self = .pane(id)
            return
        }
        let ratio = try container.decode(Double.self, forKey: .ratio)
        guard ratio >= SplitLayout.minimumRatio, ratio <= 1 - SplitLayout.minimumRatio else {
            throw DecodingError.dataCorruptedError(
                forKey: .ratio,
                in: container,
                debugDescription: "a ratio outside its limits"
            )
        }
        self = .split(
            try container.decode(SplitAxis.self, forKey: .axis),
            ratio: ratio,
            first: try container.decode(SplitLayout.self, forKey: .first),
            second: try container.decode(SplitLayout.self, forKey: .second)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
            case .pane(let id):
                try container.encode(id, forKey: .pane)
            case .split(let axis, let ratio, let first, let second):
                try container.encode(axis, forKey: .axis)
                try container.encode(ratio, forKey: .ratio)
                try container.encode(first, forKey: .first)
                try container.encode(second, forKey: .second)
        }
    }
}
