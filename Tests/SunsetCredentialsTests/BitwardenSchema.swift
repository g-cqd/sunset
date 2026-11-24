/// A JSON Schema (Draft 2020-12) of the part of Bitwarden's export that Sunset reads: the shape the tests' documents must have to be called
/// an export, checked by AemiJSON's validator, so that a property about "any export" is about exports and not about whatever the generator made.
enum BitwardenSchema {
    static let text = #"""
        {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "type": "object",
          "required": ["items"],
          "properties": {
            "encrypted": {"type": "boolean"},
            "folders": {
              "type": "array",
              "items": {"type": "object", "required": ["id", "name"], "properties": {"id": {"type": "string"}, "name": {"type": "string"}}}
            },
            "items": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["type", "name"],
                "properties": {
                  "type": {"enum": [1, 2, 3, 4]},
                  "name": {"type": "string"},
                  "notes": {"type": ["string", "null"]},
                  "favorite": {"type": "boolean"},
                  "folderId": {"type": ["string", "null"]},
                  "deletedDate": {"type": ["string", "null"]},
                  "fields": {"type": "array", "items": {"type": "object", "required": ["name", "type"]}},
                  "login": {"type": "object", "required": ["username", "password"]},
                  "card": {"type": "object"},
                  "identity": {"type": "object"},
                  "secureNote": {"type": "object"}
                },
                "allOf": [
                  {"if": {"properties": {"type": {"const": 1}}}, "then": {"required": ["login"]}},
                  {"if": {"properties": {"type": {"const": 2}}}, "then": {"required": ["secureNote"]}},
                  {"if": {"properties": {"type": {"const": 3}}}, "then": {"required": ["card"]}},
                  {"if": {"properties": {"type": {"const": 4}}}, "then": {"required": ["identity"]}}
                ]
              }
            }
          }
        }
        """#
}
