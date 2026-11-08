/// Pieces of output that between them touch every part of the renderer: text, wide characters, clusters, colours, attributes, cursor moves, scrolling,
/// erasing, cursor shapes, reverse video, palette changes, the alternate screen.
enum DifferentialPieces {
    static let all: [String] = [
        "hello", " ", "x", "日本", "e\u{301}", "👍🏽", "\r\n", "\r\n", "\n", "\r", "\u{08}", "\t",
        "\(esc)[5m", "\(esc)[1m", "\(esc)[3m", "\(esc)[4m", "\(esc)[4:3m", "\(esc)[7m", "\(esc)[2m", "\(esc)[9m",
        "\(esc)[53m",
        "\(esc)[0m",
        "\(esc)[31m", "\(esc)[42m", "\(esc)[38;5;123m", "\(esc)[48;2;10;200;30m", "\(esc)[58;2;200;0;0m",
        "\(esc)[H", "\(esc)[3;4H", "\(esc)[2;1H", "\(esc)[A", "\(esc)[3C", "\(esc)[2D",
        "\(esc)[K", "\(esc)[1K", "\(esc)[2K", "\(esc)[J", "\(esc)[1J", "\(esc)[2J", "\(esc)[2@", "\(esc)[2P",
        "\(esc)[L",
        "\(esc)[M", "\(esc)[S", "\(esc)[T",
        "\(esc)[3 q", "\(esc)[5 q", "\(esc)[2 q", "\(esc)[?25l", "\(esc)[?25h", "\(esc)[?5h", "\(esc)[?5l",
        "\(esc)]4;1;#336699\u{7}", "\(esc)]104\u{7}", "\(esc)[?1049h", "\(esc)[?1049l", "\(esc)[2;4r", "\(esc)[r"
    ]
}
