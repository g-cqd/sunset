package import Foundation

extension BinaryCookies.Cookie {
    /// The cookie as `HTTPCookie` takes it, to be set in a `WKHTTPCookieStore`: a host-only cookie's domain has no leading
    /// dot, as in the jar.
    package var httpProperties: [HTTPCookiePropertyKey: Any] {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name, .value: value, .domain: domain, .path: path, .expires: expires
        ]
        if secure { properties[.secure] = "TRUE" }
        if httpOnly { properties[HTTPCookiePropertyKey("HttpOnly")] = "TRUE" }
        switch sameSite {
            case .lax: properties[.sameSitePolicy] = HTTPCookieStringPolicy.sameSiteLax
            case .strict: properties[.sameSitePolicy] = HTTPCookieStringPolicy.sameSiteStrict
            case nil: break
        }
        return properties
    }
}
