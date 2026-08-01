//
//  PersistenceCoding.swift
//  GutCheck
//
//  Shared JSON coders for the SwiftData layer.
//

import Foundation

/// Coders used to store nested value types (food items, dosage) inside a
/// SwiftData entity as a blob.
///
/// Nested `Codable` structs are stored as encoded `Data` rather than being
/// modelled as SwiftData relationships. Nothing in the app queries *into* those
/// nested values — food items are always loaded as part of their meal — so a
/// relationship would buy nothing and cost a join plus a second entity to keep
/// in step with the struct.
enum PersistenceCoding {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Encodes a value, returning empty `Data` if encoding fails.
    ///
    /// A meal whose food items fail to encode is still worth keeping — the user
    /// logged it, and losing the record entirely would be worse than losing the
    /// item breakdown.
    static func encode<T: Encodable>(_ value: T) -> Data {
        (try? encoder.encode(value)) ?? Data()
    }

    /// Decodes a value, returning `nil` for empty or unreadable data.
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        guard !data.isEmpty else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
