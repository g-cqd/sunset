/// The templates that come with Sunset (ADR-0092), written as one table: per line its fixed id, name, symbol, and its
/// fields as `Name:kind`, a constraint after a slash (`/luhn`, `/future`, `/length3-4`, `/range1-65535`), a choice's
/// options in parentheses. Read once (`EntryTemplate+Table`); `VaultEntryTests` checks what it gives.
extension EntryTemplate {
    static let table = """
        01|Login|key|Username:text; Password:concealed; Website:url; One-Time Code:oneTimeCode
        02|Card|creditcard|Cardholder:text; Number:cardNumber/luhn; Expiry:monthYear/future; \
        Security Code:concealed/length3-4; PIN:concealed
        03|Identity|person.text.rectangle|First Name:text; Last Name:text; Email:email; Phone:phone; Address:address; \
        Birthday:date
        04|Secure Note|note.text|
        05|Licence|doc.badge.gearshape|Product:text; Licence Key:concealed; Licensed To:text; Email:email; \
        Purchased:date; Expires:date/future
        06|SSH Key|terminal|Private Key:sshKey; Public Key:multiline; Passphrase:concealed
        07|Wi-Fi|wifi|Network:text; Password:concealed; Security:choice(WPA3,WPA2,WEP,None)
        08|Bank Account|building.columns|Bank:text; Account Holder:text; IBAN:text; BIC:text; PIN:concealed
        09|Passport|globe|Full Name:text; Number:text; Country:text; Issued:date; Expires:date/future
        10|API Key|chevron.left.forwardslash.chevron.right|Service:text; Key:concealed; Secret:concealed; \
        Website:url; Expires:date/future
        11|Server|server.rack|Host:text; Port:number/range1-65535; Username:text; Password:concealed
        """

    public static let shipped: [Self] = table.split(separator: "\n").compactMap { read(line: String($0)) }

    public static let login = shipped[0]
    public static let card = shipped[1]
    public static let secureNote = shipped[3]
    public static let server = shipped[10]
}
