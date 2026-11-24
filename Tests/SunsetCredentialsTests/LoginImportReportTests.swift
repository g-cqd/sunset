import Foundation
import Testing

@testable import SunsetCredentials

/// What the person is told before and after an import: the program the file seems to come from, how many logins, what is left out and why.
@Suite("Saying what an import holds")
struct LoginImportReportTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    @Test func `the lines: logins, then what is left out, each only when there is something, singular and plural`()
        throws
    {
        let file = """
            folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp
            ,,login,One,,,0,https://a.example.com,u,p,
            ,,login,Two,,,0,https://b.example.com,u,q,"no code: 1890"
            ,,login,Dup,,,0,https://a.example.com,u,p,
            ,,note,Note,x,,0,,,,
            ,,card,Card,x,,0,,,,
            ,,login,Blank,,,0,,,,
            """
        let imported = try LoginImport.read(file, site: site).leavingOut(held: [], site: site)
        #expect(imported.sourceName == "Bitwarden")
        #expect(
            imported.report == [
                "2 logins", "1 already in the vault or earlier in the file",
                "3 rows are not logins (2 notes, cards or archived items, 1 empty)",
                "1 one-time code could not be read and was left out"
            ]
        )
        let one = try LoginImport.read("name,url,username,password,note\nA,https://a.example.com,u,p,\n", site: site)
        #expect(one.report == ["1 login"])
    }
}
