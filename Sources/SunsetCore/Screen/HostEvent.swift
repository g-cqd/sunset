/// Something the program asked the host to do, that the core cannot (it never touches the system): the host applies the policy of ADR-0010 and does it.
public enum HostEvent: Sendable, Equatable {
    /// OSC 52: put this text on the clipboard.
    case clipboardWrite(String)
    /// OSC 9, 777 and 99: show a notification (title and body are sanitised and bounded; either may be empty).
    case notification(title: String, body: String)
}
