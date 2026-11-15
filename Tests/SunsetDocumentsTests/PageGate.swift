/// Holds whoever makes a page until the test lets it through, and says when it has arrived: a long page being made, without
/// a clock.
actor PageGate {
    private var arrivals = 0
    private var open = false
    private var waitingToPass: [CheckedContinuation<Void, Never>] = []
    private var waitingForArrival: [CheckedContinuation<Void, Never>] = []

    /// Called by the maker: waits here until `release`.
    func pass() async {
        arrivals += 1
        for waiter in waitingForArrival { waiter.resume() }
        waitingForArrival = []
        guard !open else { return }
        await withCheckedContinuation { waitingToPass.append($0) }
    }

    /// Waits until a maker is held here.
    func arrived() async {
        guard arrivals == 0 else { return }
        await withCheckedContinuation { waitingForArrival.append($0) }
    }

    /// Lets everyone through, now and after.
    func release() {
        open = true
        for waiter in waitingToPass { waiter.resume() }
        waitingToPass = []
    }
}
