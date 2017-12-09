//
//  Rating.swift
//  App
//
//  Created by Daniel Skevarp on 2017-11-16.
//

import Foundation
import Vapor
import FluentProvider

final class Rating : Model{
    var storage: Storage = Storage()
    var ratedObject : String
    var ratedObjectId : Identifier
    var ratedBy : Identifier
    var rating : Int
    var timestamp : Double
    
    init(ratedObject _rob : String, ratedObjectId _robId : Identifier, ratedBy _ratedBy : Identifier, rating _rating : Int, timestamp _stamp : Double = Date().timeIntervalSince1970) {
        self.ratedObject = _rob
        self.ratedObjectId = _robId
        self.timestamp = _stamp
        self.ratedBy = _ratedBy
        self.rating = _rating
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("id", self.id)
        try row.set("ratedObject" , ratedObject)
        try row.set("ratedObjectId", ratedObjectId)
        try row.set("ratedBy", ratedBy)
        try row.set("timestamp", timestamp)
        try row.set("rating", rating)
        return row
    }
    
    required init(row: Row) throws {
        ratedObject = try row.get("ratedObject")
        ratedObjectId = try row.get("ratedObjectId")
        ratedBy = try row.get("ratedBy")
        timestamp = try row.get("timestamp")
        rating = try row.get("rating")
        id = try row.get("id")
    }
    
    static func getRatingForObject(Object _object: String, ID _id : Identifier) throws -> [Rating] {
        let ratings = try Rating.makeQuery().and( { andGroup in
            try andGroup.filter("ratedObject", .equals, _object)
            try andGroup.filter("ratedObjectId", .equals, _id)
        }).all()
        
        return ratings
    }
}

extension Rating: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(ratedObject: try json.get("ratedObject"),
                  ratedObjectId: try json.get("ratedObjectId"),
                  ratedBy: try json.get("ratedBy"),
                  rating: try json.get("rating"),
                  timestamp: try json.get("timestamp"))
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("ratedObject", ratedObject)
        try json.set("ratedObjectId", ratedObjectId)
        try json.set("id", id)
        try json.set("ratedBy", ratedBy)
        try json.set("timestamp", timestamp)
        try json.set("rating", rating)
        return json
    }
}

extension Rating: Timestampable { }

extension Rating: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "ratedBy", foreignKeyName: "rating_ratedBy")
            builder.string("ratedObject")
            builder.int("ratedObjectId")
            builder.double("timestamp")
            builder.int("rating")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

