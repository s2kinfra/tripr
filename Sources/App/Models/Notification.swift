//
//  Notification.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-27.
//

import Foundation
import FluentProvider
import Vapor


final class Notification : Model {
    var storage: Storage = Storage()
    var relatedObject : String
    var relatedObjectId : Identifier
    var receiver : Identifier
    var sender : Identifier
    var comment : String
    var timestamp : Double
    var read : Bool
    
    
    init(relatedObject _object : String,
         relatedObjectId _objId: Identifier,
         receiver _rec : Identifier,
         sender _sender : Identifier ,
         comment _comment : String = "",
         timestamp _stamp : Double = Date().timeIntervalSince1970,
         read _read : Bool = false) {
        
        relatedObject = _object
        relatedObjectId = _objId
        receiver = _rec
        sender = _sender
        comment = _comment
        timestamp = _stamp
        read = _read
    }
    
    func send(inBackground _back : Bool = true) throws
    {
        if _back {
            
        }else {
            
        }
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("relatedObject", relatedObject)
        try row.set("relatedObjectId", relatedObjectId)
        try row.set("receiver", receiver)
        try row.set("sender", sender)
        try row.set("comment", comment)
        try row.set("read", read)
        try row.set("timestamp", timestamp)
        return row
    }
    
    required init(row: Row) throws {
        relatedObject = try row.get("relatedObject")
        relatedObjectId = try row.get("relatedObjectId")
        receiver = try row.get("receiver")
        sender = try row.get("sender")
        comment = try row.get("comment")
        read = try row.get("read")
        timestamp = try row.get("timestamp")
        
    }
}

extension Notification: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("relatedObject")
            builder.int("relatedObjectId")
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "receiver", foreignKeyName: "receiver")
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "sender", foreignKeyName: "sender")
            builder.string("comment")
            builder.double("timestamp")
            builder.bool("read")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Notification : Timestampable {}

