//
//  Trip+Model.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-21.
//

import Vapor
import FluentProvider

extension Trip: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(name: try json.get("name"),
                  tripStart: try json.get("tripStart"),
                  tripEnd: try json.get("tripEnd"),
                  createdBy: try json.get("createdBy"),
                  description: try json.get("tripDescription")
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("name", name)
        try json.set("tripStart", tripStart)
        try json.set("id", id)
        try json.set("tripEnd", tripEnd)
        try json.set("createdBy", createdBy)
        try json.set("tripDescription", tripDescription)
        try json.set("attendants", try attendees.all().makeJSON())
        try json.set("comments", try comments.makeJSON())
        try json.set("feeds", feeds)
        try json.set("places", places)
        try json.set("coverPhoto", try self.cover.makeJSON())
        return json
    }
}


extension Trip : Parameterizable {
    /// the unique key to use as a slug in route building
    public static var uniqueSlug: String {
        return "id"
    }
    
    // returns the found model for the resolved url parameter
    public static func make(for parameter: String) throws -> Trip {
        guard let found = try Trip.find(parameter) else {
            throw Abort(.notFound, reason: "No \(Trip.self) with that identifier was found.")
        }
        return found
    }
}

extension Trip : Model {
    convenience init(row: Row) throws {
        self.init()
        name = try row.get("name")
        tripStart = try row.get("tripStart")
        tripEnd = try row.get("tripEnd")
        publicTrip = try row.get("publicTrip")
        tripDescription = try row.get("tripDescription")
        publicTrip = try row.get("publicTrip")
        createdBy = try row.get("createdBy")
        id = try row.get(idKey)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        //try row.set(User.foreignIdKey, userId)
        try row.set("name", name)
        try row.set("tripStart", tripStart)
        try row.set("tripEnd", tripEnd)
        try row.set("publicTrip", publicTrip)
        try row.set("tripDescription", tripDescription)
        try row.set("publicTrip", publicTrip)
        try row.set("createdBy", createdBy)
        return row
    }
}

// MARK: Fluent Preparation
extension Trip: Timestampable { }

extension Trip: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("name")
            builder.double("tripStart")
            builder.double("tripEnd")
            builder.longText("tripDescription")
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "createdBy", foreignKeyName: "trip_createdby")
            builder.bool("publicTrip")

        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
