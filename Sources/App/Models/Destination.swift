//
//  Destination.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-20.
//

import Vapor
import FluentProvider

final class Destination : Model {
    
    var storage: Storage = Storage()
    
    var name : String?
    var startDate : Date?
    var endDate : Date?
    var longitude : Double?
    var latitude : Double?
    var createdBy : Identifier
    var relatedObject : String?
    var relatedObjectId : Identifier?
    var Places : [Place]?
    
    required init(row: Row) throws {
        name = try row.get("name")
        startDate = try row.get("startDate")
        startDate = try row.get("startDate")
        endDate = try row.get("endDate")
        longitude = try row.get("longitude")
        latitude = try row.get("latitude")
        createdBy = try row.get("createdBy")
        relatedObject = try row.get("relatedObject")
        relatedObjectId = try row.get("relatedObjectId")
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set("startDate", startDate)
        try row.set("longitude", longitude)
        try row.set("endDate", endDate)
        try row.set("latitude", latitude)
        try row.set("createdBy", createdBy)
        try row.set("relatedObject", relatedObject)
        try row.set("relatedObjectId", relatedObjectId)
        return row
    }
    
}



extension Destination: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("name")
            builder.double("startDate")
            builder.double("endDate")
            builder.double("longitude")
            builder.double("latitude")
            builder.string("relatedObject", optional: true, unique: false)
            builder.string("relatedObjectId", optional: true, unique: false)
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "createdBy", foreignKeyName: "dest_createdBy")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}


extension Destination: Envyable {
    func getCreators() -> [Identifier] {
        var creators = [Identifier]()
        creators.append(createdBy)
        return creators
    }
}
extension Destination: Attachable {
    var objectIdentifier: Identifier{
        get{
            return self.id!
        }
    }
}
extension Destination: Suggestable { }
extension Destination: Timestampable { }
