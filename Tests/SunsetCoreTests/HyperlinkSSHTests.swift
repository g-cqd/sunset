import Testing

@testable import SunsetCore

/// `ssh:` links a terminal may open (the system hands them to the ssh handler, which runs `ssh` with the address in it):
/// what draft-ietf-secsh-scp-sftp-ssh-uri-04 §3.3 allows (`ssh://[userinfo[;params]@]host[:port][path]`), and never a
/// user or host that `ssh` would read as an option, nor blanks or controls, percent-encoded or not.
@Suite("Terminal links: ssh addresses") struct HyperlinkSSHTests {
    private func opens(_ address: String) -> Bool {
        HyperlinkPolicy.opens(address, localHost: "mac.local")
    }

    @Test(arguments: [
        "ssh://host", "ssh://host/path", "ssh://user@host.example.com", "ssh://user@host.example.com:2222",
        "ssh://user;fingerprint=ssh-dss-c1-b1@host.example.com", "ssh://[2001:db8::1]:22", "ssh://192.0.2.7",
        "ssh://first.last@build-01.local", "SSH://Host"
    ])
    func `the draft's addresses open`(address: String) {
        #expect(opens(address))
    }

    @Test(arguments: [
        "ssh://-oProxyCommand=open%20-a%20Calculator@host", "ssh://-oProxyCommand=x", "ssh://user@-host",
        "ssh://%2DoProxyCommand=x@host", "ssh://user@%2dhost", "ssh://us er@host", "ssh://user@ho%20st",
        "ssh://user@host%0A-oX", "ssh://user@host:22x", "ssh://user@host:", "ssh://user@", "ssh://@host", "ssh://",
        "ssh://user@host\u{0}", "ssh://user%00@host", "ssh://host:-1", "ssh://ho'st", "ssh://host;rm"
    ])
    func `options, blanks, controls and malformed ones do not`(address: String) {
        #expect(!opens(address))
    }

    /// Random addresses built from the characters that matter: none traps, and none that opens has a user or host that
    /// begins with `-`, or a blank or control, once its escapes are decoded.
    @Test func `random addresses never open as an option or with a blank`() {
        var random = SystemRandomNumberGenerator()
        let alphabet = Array("ab-@:;=,%2Dd0A /[]._~\u{0}\n'".unicodeScalars)
        for _ in 0 ..< 20_000 {
            let length = Int.random(in: 0 ... 14, using: &random)
            var tail = ""
            for _ in 0 ..< length { tail.unicodeScalars.append(alphabet.randomElement(using: &random) ?? "a") }
            let address = "ssh://" + tail
            guard opens(address) else { continue }
            let decoded = tail.removingPercentEncodingForTest()
            let authority = decoded.prefix { $0 != "/" }
            let user =
                authority.contains("@") ? authority.split(separator: "@", omittingEmptySubsequences: false)[0] : ""
            let host = authority.split(separator: "@", omittingEmptySubsequences: false).last ?? ""
            #expect(!user.hasPrefix("-") && !host.hasPrefix("-"), "\(address)")
            #expect(!decoded.unicodeScalars.contains { $0.value <= 0x20 || $0.value == 0x7F }, "\(address)")
        }
    }
}

extension String {
    /// `%XX` escapes decoded byte for byte (Latin-1 for the bytes past ASCII): enough to look for `-`, blanks and controls.
    fileprivate func removingPercentEncodingForTest() -> String {
        var out = ""
        var bytes = utf8[...]
        while let byte = bytes.first {
            bytes = bytes.dropFirst()
            if byte == UInt8(ascii: "%"), bytes.count >= 2,
                let value = UInt8(String(decoding: bytes.prefix(2), as: UTF8.self), radix: 16)
            {
                out.unicodeScalars.append(Unicode.Scalar(value))
                bytes = bytes.dropFirst(2)
            } else {
                out.unicodeScalars.append(Unicode.Scalar(byte))
            }
        }
        return out
    }
}
