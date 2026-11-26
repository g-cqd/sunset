import Foundation
import Testing

@testable import SunsetCredentials

/// Logins read from the CSV a browser or a password manager exports (roadmap 0095 D): the columns found by their headers, a login
/// made of each row that is one, the rows that are not logins said and counted, what the vault holds already left out.
@Suite("Importing logins from CSV")
struct LoginImportTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    private func value(_ entry: VaultEntry, _ name: String) -> String? {
        entry.field(named: name)?.value
    }

    @Test func `Apple Passwords' export: title, URL, user, password, notes and the code's link`() throws {
        let file = """
            Title,URL,Username,Password,Notes,OTPAuth
            Example,https://example.com/login,ada,pw1,"first line
            second line",otpauth://totp/Example:ada?secret=JBSWY3DPEHPK3PXP&issuer=Example
            """
        let imported = try LoginImport.read(file, site: site)
        #expect(imported.source == .applePasswords)
        let entry = try #require(imported.entries.first)
        #expect(imported.entries.count == 1 && entry.title == "Example")
        #expect(value(entry, "Website") == "https://example.com/login")
        #expect(value(entry, "Username") == "ada" && value(entry, "Password") == "pw1")
        #expect(entry.note == "first line\nsecond line")
        #expect(value(entry, "One-Time Code")?.hasPrefix("otpauth://totp/") == true)
        #expect(entry.template == EntryTemplate.login.id)
    }

    @Test func `Chrome's: name, url, username, password, note; an address with no scheme gets https`() throws {
        let file = "name,url,username,password,note\nShop,shop.example.org,bo,pw2,note here\n"
        let imported = try LoginImport.read(file, site: site)
        #expect(imported.source == .chrome)
        let entry = try #require(imported.entries.first)
        #expect(entry.title == "Shop" && value(entry, "Website") == "https://shop.example.org")
        #expect(entry.note == "note here")
    }

    @Test func `Firefox's has no title: the site names the entry; its other columns are not read`() throws {
        let file = """
            url,username,password,httpRealm,formActionOrigin,guid,timeCreated,timeLastUsed,timePasswordChanged
            https://accounts.example.com,ada,pw3,,https://accounts.example.com,{guid},1,2,3
            """
        let imported = try LoginImport.read(file, site: site)
        #expect(imported.source == .firefox)
        #expect(try #require(imported.entries.first).title == "example.com")
    }

    @Test
    func
        `Bitwarden's: the first address, the folder, a favourite, a bare secret made a code, a note kept as a Secure Note`()
        throws
    {
        let file = """
            folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp
            Work,1,login,Mail,,,0,"https://mail.example.com
            https://mail.example.net",ada,pw4,JBSWY3DPEHPK3PXP
            ,,note,A secret note,body,,0,,,,
            """
        let imported = try LoginImport.read(file, site: site)
        #expect(imported.source == .bitwarden)
        let entry = try #require(imported.entries.first)
        #expect(imported.entries.count == 2 && entry.title == "Mail")
        #expect(value(entry, "Website") == "https://mail.example.com")
        #expect(entry.folder == "Work" && entry.isFavorite)
        let code = try #require(value(entry, "One-Time Code"))
        #expect((try? OneTimeCodeURI(code))?.secret == (try? Base32.decode("JBSWY3DPEHPK3PXP")))
        #expect(imported.skipped.isEmpty)
        #expect(imported.entries.last?.template == EntryTemplate.secureNote.id)
        #expect(imported.entries.last?.note == "body")
    }

    @Test func `1Password's: Title, Url, tags split, archived rows left out`() throws {
        let file =
            "Title,Url,Username,Password,OTPAuth,Favorite,Archived,Tags,Notes\nSite,https://s.example.com,u,p,,0,0,\"a,b\",\nOld,https://o.example.com,u,p,,0,1,,\n"
        let imported = try LoginImport.read(file, site: site)
        #expect(imported.source == .onePassword)
        #expect(imported.entries.map(\.title) == ["Site"] && imported.entries[0].tags == ["a", "b"])
        #expect(imported.skipped.map(\.reason) == [.archived])
    }

    @Test
    func
        `a row with no password and no username is not a login, said with its row; a code it cannot read is dropped from a login that is kept, and said too`()
        throws
    {
        let file = "name,url,username,password,note\nEmpty,https://e.example.com,,,\nOk,https://o.example.com,u,p,\n"
        let imported = try LoginImport.read(file, site: site)
        #expect(imported.entries.map(\.title) == ["Ok"])
        #expect(imported.skipped == [LoginImport.Skipped(row: 2, reason: .empty)])
        let bad = try LoginImport.read(
            "Title,URL,Username,Password,Notes,OTPAuth\nX,https://x.example.com,u,p,,no code here: 1890!\n",
            site: site
        )
        #expect(bad.entries.count == 1 && (value(bad.entries[0], "One-Time Code") ?? "").isEmpty)
        #expect(bad.skipped.isEmpty && bad.warnings == [LoginImport.Warning(row: 2, reason: .unreadableCode)])
    }

    @Test func `a file with no password column, or nothing, is refused, not guessed at`() {
        #expect(throws: LoginImport.Failure.noLoginColumns) { try LoginImport.read("a,b\n1,2\n", site: site) }
        #expect(throws: LoginImport.Failure.noLoginColumns) { try LoginImport.read("", site: site) }
    }

    @Test func `what the vault holds already is left out: the same site, user and password; a new password is kept`()
        throws
    {
        let file = "name,url,username,password,note\nA,https://a.example.com,u,p,\nB,https://b.example.com,u,p2,\n"
        let imported = try LoginImport.read(file, site: site)
        var held = EntryTemplate.login.makeEntry(title: "A already")
        for (name, text) in [("Website", "https://a.example.com/signin"), ("Username", "u"), ("Password", "p")] {
            held.set(try #require(held.field(named: name)?.id), text)
        }
        let fresh = imported.leavingOut(held: [held], site: site)
        #expect(fresh.entries.map(\.title) == ["B"] && fresh.duplicates == 1)
    }

    @Test func `a quoted cell that starts with a formula character is kept as the file has it`() throws {
        let file = "name,url,username,password,note\nX,https://x.example.com,u,\"=1+1\",\n"
        let entry = try #require(try LoginImport.read(file, site: site).entries.first)
        #expect(value(entry, "Password") == "=1+1")
    }
}
