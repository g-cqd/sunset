/// The welcome's first page: the first launch's, or the easter egg's (Option on the Sunset menu).
enum WelcomeGreeting {
    case first
    case again

    var text: (title: String, line: String) {
        switch self {
            case .first:
                (
                    "Welcome to Sunset",
                    "A terminal, the web and documents, in tabs and Spaces of one window. A few questions follow; every answer can change later in Settings."
                )
            case .again:
                (
                    "You found the hidden sunset",
                    "Few people hold Option in a menu. Your reward: the sun sets again, whenever you like. That is the whole prize. Your windows come back when you close this."
                )
        }
    }
}
