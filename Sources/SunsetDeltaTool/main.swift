import Foundation
import SunsetUpdate

// Sunset's deltas and update packages from the command line (roadmap 0122 C): the release routine makes them, a person can
// check one.
//
//   SunsetDeltaTool make OLD NEW DELTA                     the delta that turns the file OLD into NEW
//   SunsetDeltaTool apply OLD DELTA NEW                    NEW from OLD and DELTA (checked against the SHA-256 it names)
//   SunsetDeltaTool package OLD.app NEW.app FROM TO OUT    the update from build FROM to build TO
//   SunsetDeltaTool stage PACKAGE RUNNING.app STAGING.app  the package applied, as Sunset applies it

let words = Array(CommandLine.arguments.dropFirst())
let usage =
    "usage: SunsetDeltaTool make OLD NEW DELTA | apply OLD DELTA NEW | package OLD NEW FROM TO OUT | stage PACKAGE APP STAGING\n"

/// Runs `words`; returns what it wrote, or nil for a wrong use.
func run(_ words: [String]) throws -> String? {
    let urls = words.dropFirst().map { URL(filePath: $0) }
    switch (words.first, words.count) {
        case ("make", 4):
            let delta = try BinaryDelta.make(from: Data(contentsOf: urls[0]), to: Data(contentsOf: urls[1]))
            try delta.write(to: urls[2])
            return "\(urls[2].path): \(delta.count) bytes"
        case ("apply", 4):
            try BinaryDelta.apply(Data(contentsOf: urls[1]), to: Data(contentsOf: urls[0])).write(to: urls[2])
            return urls[2].path
        case ("package", 6):
            guard let from = Int(words[3]), let to = Int(words[4]) else { return nil }
            let package = try UpdatePackage.make(old: urls[0], new: urls[1], from: from, to: to)
            try package.write(to: urls[4])
            return "\(urls[4].path): \(package.count) bytes"
        case ("stage", 4):
            let package = try UpdatePackage(decoding: Data(contentsOf: urls[0]))
            try UpdateStaging.build(package, running: urls[1], staging: urls[2])
            return "\(urls[2].path): build \(package.to), every file as its manifest says"
        default:
            return nil
    }
}

do {
    guard let said = try run(words) else {
        FileHandle.standardError.write(Data(usage.utf8))
        exit(64)
    }
    print(said)
} catch {
    FileHandle.standardError.write(Data("SunsetDeltaTool: \(error)\n".utf8))
    exit(1)
}
