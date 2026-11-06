/// A plain base64 encoder for building test input without the code under test.
enum Base64Fixture {
    static func encode(_ text: String) -> String {
        let table = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
        var bytes = Array(text.utf8)
        var result = ""
        while !bytes.isEmpty {
            let chunk = Array(bytes.prefix(3))
            bytes.removeFirst(chunk.count)
            let value = chunk.enumerated().reduce(0) { $0 | Int($1.element) << (16 - 8 * $1.offset) }
            for index in 0 ... chunk.count { result.append(table[(value >> (18 - 6 * index)) & 63]) }
            result += String(repeating: "=", count: 3 - chunk.count)
        }
        return result
    }
}
