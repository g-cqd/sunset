// t116: can the terminal see, from the PTY's master side, that a program turned echo off (a password prompt)? (2026-11-19)
// A shell under forkpty runs `stty -echo; sleep 1; stty echo; sleep 1`; the master's termios is read every 200 ms.
import Darwin
import Foundation

var master: Int32 = -1
let child = forkpty(&master, nil, nil, nil)
if child == 0 {
    let texts: [String] = ["sh", "-c", "sleep 0.5; stty -echo; sleep 1.2; stty echo; sleep 1"]
    let words: [UnsafeMutablePointer<CChar>?] = texts.map { strdup($0) }
    execv("/bin/sh", words + [nil])
    exit(127)
}
var seen: [String] = []
for step in 0 ..< 15 {
    var attributes = termios()
    let read = tcgetattr(master, &attributes)
    let echo =
        read == 0 ? ((attributes.c_lflag & tcflag_t(ECHO)) != 0 ? "echo" : "NO ECHO") : "tcgetattr failed (\(errno))"
    let canonical = (attributes.c_lflag & tcflag_t(ICANON)) != 0 ? "icanon" : "raw"
    seen.append("\(step * 200) ms: \(echo), \(canonical)")
    usleep(200_000)
}
kill(child, SIGTERM)
print(seen.joined(separator: "\n"))
