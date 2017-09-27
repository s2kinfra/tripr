//
//  Envy.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-21.
//

import Foundation
import Vapor
import FluentProvider

final class Envy : Model{
    var storage: Storage = Storage()
    var enviedBy : User
    var enviedObject : String
    var enviedObjectId : Identifier
    var timestamp : Double
    
    init(enviedBy _user: User, enviedObject _object : String, enviedObjectId _id : Identifier) {
        self.enviedBy = _user
        self.enviedObject = _object
        self.timestamp = Date().timeIntervalSince1970
        self.enviedObjectId = _id
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("id", self.id)
        try row.set("enviedBy" , enviedBy.id)
        try row.set("enviedObject", enviedObject)
        try row.set("enviedObjectId", enviedObjectId)
        try row.set("timestamp", timestamp)
        return row
    }
    
    required init(row: Row) throws {
        enviedBy = try User.find(try row.get("enviedBy"))!
        enviedObject = try row.get("enviedObject")
        enviedObjectId = try row.get("enviedObjectId")
        timestamp = try row.get("timestamp")
        id = try row.get("id")
    }
    
    static func getEnviesForObject(Object _object: String, ID _id : Identifier) throws -> [Envy] {
        let envies = try Envy.makeQuery().and( { andGroup in
             try andGroup.filter("enviedObject", .equals, _object)
             try andGroup.filter("enviedObjectId", .equals, _id)
            }).all()
        
        return envies
    }
    
    
    
}

extension Envy: Timestampable { }

extension Envy: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.foreignId(for: File.self, optional: false, unique: false, foreignIdKey: "enviedBy", foreignKeyName: "enviedBy")
            builder.string("enviedObject")
            builder.int("enviedObjectId")
            builder.double("timestamp")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

