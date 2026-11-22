import SunsetHost
import Testing

/// The `--keys` of sunset-run and sunset-render, read in one place (each tool had its own copy).
@Suite("Keys written as text")
struct KeyTextTests {
    @Test func `escapes become their keys; any other backslash is that thing; a trailing one stays`() {
        #expect(KeyText.unescape(#"ls\n"#) == "ls\n")
        #expect(KeyText.unescape(#"\e[A\r\t"#) == "\u{1B}[A\r\t")
        #expect(KeyText.unescape(#"a\\b\q"#) == #"a\bq"#)
        #expect(KeyText.unescape(#"end\"#) == #"end\"#)
    }
}
