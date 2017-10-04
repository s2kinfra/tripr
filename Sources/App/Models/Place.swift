//
//  Place.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-20.
//

import Foundation
import Vapor
import FluentProvider

struct Adress {
    var street : String
    var houseNumber: Int
    var city : String
    var country : String
}

final class Place : Model {
    var storage: Storage = Storage()
    
    var longitude : Double
    var latitude : Double
    var name : String
    var country : String?
    var city : String?
    var temperature : String?
    var relatedObject : String?
    var relatedObjectId : Identifier?
    var createdBy : Identifier
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("longitude" , longitude)
        try row.set("latitude", latitude)
        try row.set("name", name)
        try row.set("country", country)
        try row.set("city", city)
        try row.set("relatedObject", relatedObject)
        try row.set("relatedObjectId", relatedObjectId)
        try row.set("createdBy", createdBy)
        return row
    }
    
    init(row: Row) throws {
        longitude = try row.get("longitude")
        latitude = try row.get("latitude")
        name = try row.get("name")
        country = try row.get("country")
        city = try row.get("city")
        relatedObject = try row.get("relatedObject")
        relatedObjectId = try row.get("relatedObjectId")
        createdBy = try row.get("createdBy")
    }
}


extension Place: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("name")
            builder.double("longitude")
            builder.double("latitude")
            builder.string("country")
            builder.string("city")
            builder.string("relatedObject", optional: true, unique: false)
            builder.string("relatedObjectId", optional: true, unique: false)
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "createdBy", foreignKeyName: "place_createdBy")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}


extension Place: Envyable {
    func getCreators() -> [Identifier] {
        var creators = [Identifier]()
        creators.append(createdBy)
        return creators
    }
}
extension Place: Attachable {
    var objectIdentifier: Identifier{
        get{
            return self.id!
        }
    }
}
extension Place: Suggestable { }
extension Place: Timestampable { }


