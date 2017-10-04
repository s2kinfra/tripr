//
//  Trip+Model.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-21.
//

import Vapor
import FluentProvider

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
            builder.string("tripDescription")
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "createdBy", foreignKeyName: "trip_createdby")
            builder.bool("publicTrip")

        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
