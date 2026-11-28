# KeePass fixtures

Made with pykeepass 4.2.0 (`create_database`, then the header's cipher and key derivation changed and saved again), and
read back by pykeepass before being kept:

- `keepass-argon2-aes.kdbx`: KDBX 4.0, AES-256, Argon2d (64 MiB, 14 passes, 2 lanes), gzip; password `correct horse`.
  Groups `Work / Team`; "Example Mail" (username, password, address, two-line notes, tags `mail`, `work`, a TOTP `otp`,
  a protected `PIN`, a plain `Recovery`, an attachment `readme.txt`, one earlier password in its history); "Just a note"
  (notes only); "Old thing" in the recycle bin.
- `keepass-aeskdf-chacha20.kdbx`: the same database with ChaCha20 and AES-KDF (6,000 rounds).
- `keepass-argon2id-keyfile.kdbx`: KDBX 4.0, Argon2id (1 MiB, 2 passes), password `pw` and the key file
  `keepass-keyfile.hex` (64 hex digits); one entry "Keyed".
