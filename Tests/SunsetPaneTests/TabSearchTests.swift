import Testing

@testable import SunsetPane

@Suite("Tab search") struct TabSearchTests {
    private func rank(_ query: String, _ items: [[String]]) -> [Int] {
        TabSearch.rank(query: query, candidates: items.enumerated().map { .init(id: $0.offset, fields: $0.element) })
    }

    @Test func `an empty query, or only spaces, keeps everything in order`() {
        #expect(rank("", [["b"], ["a"], ["c"]]) == [0, 1, 2])
        #expect(rank("  ", [["b"], ["a"]]) == [0, 1])
    }

    @Test func `matching ignores case and a candidate with no match is left out`() {
        #expect(rank("VIM", [["vim notes"], ["zsh"], ["Vimrc"]]) == [0, 2])
    }

    @Test func `a run of the query beats letters spread over the text`() {
        #expect(rank("sun", [["s-u-n"], ["sunset"]]) == [1, 0])
    }

    @Test func `letters in order still match when they are not together`() {
        #expect(rank("sns", [["sunset"]]) == [0])
        #expect(rank("tsn", [["sunset"]]).isEmpty, "the order matters")
    }

    @Test func `the start of the text or of a word beats the middle`() {
        #expect(rank("set", [["unset"], ["sunset set"], ["set"]]) == [2, 1, 0])
    }

    @Test func `every word of the query must match, in any field`() {
        let items = [["vim", "/Users/me/sunset"], ["vim", "/tmp"], ["zsh", "/Users/me/sunset"]]
        #expect(rank("vim sunset", items) == [0])
        #expect(rank("sunset vim", items) == [0])
    }

    @Test func `equal matches keep the order of the tabs`() {
        #expect(rank("a", [["a1"], ["a2"], ["a3"]]) == [0, 1, 2])
    }

    @Test func `the selection moves by steps, going round`() {
        #expect(TabSearch.moved(0, by: 1, count: 3) == 1)
        #expect(TabSearch.moved(2, by: 1, count: 3) == 0)
        #expect(TabSearch.moved(0, by: -1, count: 3) == 2)
        #expect(TabSearch.moved(1, by: 5, count: 3) == 0)
        #expect(TabSearch.moved(0, by: 1, count: 0) == 0)
        #expect(TabSearch.moved(7, by: 0, count: 3) == 2, "an index that is too far is brought inside")
    }
}
