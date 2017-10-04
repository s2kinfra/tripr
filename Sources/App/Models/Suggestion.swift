//
//  Suggestion.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-27.
//

import Foundation
import Vapor
import FluentProvider

final class Suggestion : Model , Envyable, Attachable, Commentable{
    var objectIdentifier: Identifier {
        get {
            return self.id!
        }
    }
    var storage: Storage = Storage()
    var createdBy : Identifier
    var suggestedObject : String
    var suggestedObjectId : Identifier
    var timestamp : Double
    
    init(createdBy _created : Identifier, suggestedObject _object : String, suggestedObjectId _objectId: Identifier, timestamp _timestamp : Double = Date().timeIntervalSince1970 ) {
        createdBy = _created
        suggestedObject = _object
        suggestedObjectId = _objectId
        timestamp = _timestamp
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("createdBy", createdBy)
        try row.set("suggestedObject", suggestedObject)
        try row.set("suggestedObjectId", suggestedObjectId)
        try row.set("timestamp", timestamp)
        return row
    }
    
    init(row: Row) throws {
        createdBy = try row.get("createdBy")
        suggestedObject = try row.get("suggestedObject")
        suggestedObjectId = try row.get("suggestedObjectId")
        timestamp = try row.get("timestamp")
    }
    
    func getCreators() -> [Identifier] {
        var creators = [Identifier]()
        creators.append(createdBy)
        return creators
    }
}

extension Suggestion: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "createdBy", foreignKeyName: "suggestion_createdBy")
            builder.string("suggestedObject")
            builder.int("suggestedObjectId")
            builder.double("timestamp")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Suggestion : Timestampable {}



