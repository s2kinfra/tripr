//
//  Comment.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-27.
//

import Foundation
import Vapor
import FluentProvider



final class Comment : Model , Attachable, Envyable{
    
    
    var objectIdentifier: Identifier {
        get {
            return self.id!
        }
    }
    var storage: Storage = Storage()
    var text : String
    var writtenBy : Identifier
    var timestamp : Double
    var commentedObject : String
    var commentedObjectId: Identifier
    
    func getCreators() -> [Identifier] {
        var creators = [Identifier]()
        creators.append(self.id!)
        return creators
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("text", text)
        try row.set("writtenBy", writtenBy)
        try row.set("timestamp", timestamp)
        try row.set("commentedObject", objectType)
        try row.set("commentedObjectId", objectIdentifier)
        try row.set("id", id)
        return row
    }
    
    init(row: Row) throws {
        text = try row.get("text")
        writtenBy = try row.get("writtenBy")
        timestamp = try row.get("timestamp")
        commentedObject = try row.get("commentedObject")
        commentedObjectId = try row.get("commentedObjectId")
        id = try row.get("id")
    }
    
    init(text _text: String, writtenBy _user: Identifier, commentedObject _object : String, commentedObjectId _objectId : Identifier)
    {
        self.commentedObjectId = _objectId
        self.commentedObject = _object
        self.text = _text
        self.writtenBy = _user
        self.timestamp = Date().timeIntervalSince1970
    }
}

extension Comment: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("object")
            builder.int("objectId")
            builder.string("text")
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "writtenBy", foreignKeyName: "comment_writtenBy")
            builder.double("timestamp")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Comment : Timestampable {}

