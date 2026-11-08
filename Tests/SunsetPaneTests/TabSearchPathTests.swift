import Testing

@testable import SunsetPane

@Suite("Tab search: paths") struct TabSearchPathTests {
    @Test func `letters spread over a path match it`() {
        let fields = ["Sunset", "/Volumes/Personal/Github/g-cqd/sunset"]
        #expect(TabSearch.rank(query: "vi", candidates: [.init(id: 0, fields: fields)]) == [0])
        #expect(TabSearch.rank(query: "sun", candidates: [.init(id: 0, fields: fields)]) == [0])
        #expect(TabSearch.rank(query: "g-cqd", candidates: [.init(id: 0, fields: fields)]) == [0])
    }
}
