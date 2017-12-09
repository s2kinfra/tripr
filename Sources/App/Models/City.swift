//
//  City.swift
//  App
//
//  Created by Daniel Skevarp on 2017-12-05.
//

import Foundation
import Vapor
import FluentProvider

final class City : Model {
    var storage: Storage = Storage()
    static var entity = "cities"
    static var name = "City"
    var region_id : Int
    var country_id : Int
    var latitude : Double
    var longitude : Double
    var name : String
    var country : String {
        get{
            do {
                return try getCountry()
            }catch {
                return ""
            }
            
        }
    }
    
    init(region_id : Int, country_id : Int, latitude: Double, longitude: Double, name : String) {
        self.region_id = region_id
        self.country_id = country_id
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("region_id", self.region_id)
        try row.set("country_id", self.country_id)
        try row.set("latitude", self.latitude)
        try row.set("longitude", self.longitude)
        try row.set("name", self.name)
        return row
    }
    
    init(row: Row) throws {
        region_id = try row.get("region_id")
        country_id = try row.get("country_id")
        latitude = try row.get("latitude")
        longitude = try row.get("longitude")
        name = try row.get("name")
    }
    
    func getCountry() throws -> String {
        let test = try City.database?.raw("SELECT name FROM countries WHERE id = \(self.country_id)")
        
        guard let data = test?.wrapped.array else {
            return ""
        }
        
        var country = ""
        
        for ctry in data {
            country = ctry.string!
        }
        
        return country
    }
    
}


extension City: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(region_id: try json.get("region_id"),
                  country_id: try json.get("country_id"),
                  latitude: try json.get("latitude"),
                  longitude: try json.get("longitude"),
                  name: try json.get("name"))
        
        self.id = try json.get("id")
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("country_id", country_id)
        try json.set("id", id)
        try json.set("latitude", latitude)
        try json.set("longitude", longitude)
        try json.set("name", name)
        return json
    }
}


extension City: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.int("region_id")
            builder.int("country_id")
            builder.double("latitude")
            builder.double("longitude")
            builder.string("name")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

