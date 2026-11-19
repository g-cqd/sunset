// RFC 6238 Appendix B's test vectors (8 digits; the seeds are ASCII "1234567890" repeated to 20, 32 and 64 bytes), with
// CryptoKit's HMAC; and Steam Guard's five characters from the same code (alphabet 23456789BCDFGHJKMNPQRTVWXY) (2026-11-19).
import CryptoKit
import Foundation

func code<H: HashFunction>(_: H.Type, seed: Data, time: UInt64, period: UInt64 = 30) -> UInt32 {
    var counter = (time / period).bigEndian
    let message = Data(bytes: &counter, count: 8)
    let mac = Array(HMAC<H>.authenticationCode(for: message, using: SymmetricKey(data: seed)))
    let offset = Int(mac[mac.count - 1] & 0x0f)
    return (UInt32(mac[offset] & 0x7f) << 24) | (UInt32(mac[offset + 1]) << 16) | (UInt32(mac[offset + 2]) << 8)
        | UInt32(mac[offset + 3])
}
let seed = { (n: Int) in Data(String(repeating: "1234567890", count: 7).utf8.prefix(n)) }
let vectors: [(UInt64, String, String, String)] = [
    (59, "94287082", "46119246", "90693936"), (1_111_111_109, "07081804", "68084774", "25091201"),
    (1_111_111_111, "14050471", "67062674", "99943326"), (1_234_567_890, "89005924", "91819424", "93441116"),
    (2_000_000_000, "69279037", "90698825", "38618901"), (20_000_000_000, "65353130", "77737706", "47863826")
]
var failures = 0
for (t, sha1, sha256, sha512) in vectors {
    let got = [
        code(Insecure.SHA1.self, seed: seed(20), time: t), code(SHA256.self, seed: seed(32), time: t),
        code(SHA512.self, seed: seed(64), time: t)
    ]
    .map { String(format: "%08u", $0 % 100_000_000) }
    let ok = got == [sha1, sha256, sha512]
    if !ok { failures += 1 }
    print(t, got, ok ? "ok" : "EXPECTED \([sha1, sha256, sha512])")
}
let alphabet = Array("23456789BCDFGHJKMNPQRTVWXY")
var full = code(Insecure.SHA1.self, seed: seed(20), time: 59)
var steam = ""
for _ in 0 ..< 5 {
    steam.append(alphabet[Int(full % 26)])
    full /= 26
}
print("steam (from the SHA-1 vector at 59):", steam)
print(failures == 0 ? "all RFC 6238 vectors pass" : "\(failures) failed")
