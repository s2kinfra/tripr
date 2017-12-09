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
    
    var name : String
    var startDate : Double?
    var endDate : Double?
    var city: City?
    var longitude : Double?
    var latitude : Double?
    var createdBy : Identifier
    var relatedObject : String?
    var relatedObjectId : Identifier?
    var places : Children<Destination,Place> {
        return children()
    }
    init(name : String, startDate : Double?, endDate: Double?, longitude : Double?, latitude: Double?, createdBy: Identifier, relatedObject : String?, relatedObjectId: Identifier? ){
        
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.longitude = longitude
        self.latitude = latitude
        self.createdBy = createdBy
        self.relatedObject = relatedObject
        self.relatedObjectId = relatedObjectId
        guard let lat = latitude , let long = longitude else {
            return
        }
        do {
            self.city = try Destination.getCityFromCoordinates(long: long, lat: lat)
        }catch{
            
        }
        
    }
    
    required init(row: Row) throws {
        name = try row.get("name")
        startDate = try row.get("startDate")
        endDate = try row.get("endDate")
        longitude = try row.get("longitude")
        latitude = try row.get("latitude")
        createdBy = try row.get("createdBy")
        relatedObject = try row.get("relatedObject")
        relatedObjectId = try row.get("relatedObjectId")
        id = try row.get("id")
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
        try row.set("id", id)
        return row
    }
    
    static func getCityFromCoordinates(long : Double, lat: Double) throws -> City? {
        let test = try Destination.database?.raw("SELECT *, ( 6371 * acos( cos( radians( \(lat) ) ) * cos( radians( `latitude` ) ) * cos( radians( `longitude` ) - radians( \(long) ) ) + sin(radians(\(lat))) * sin(radians(`latitude`)) ) ) `distance` FROM `cities` HAVING `distance` < \(20) ORDER BY `distance`  LIMIT 1")
        
        guard let data = test?.wrapped.array else {
            return nil
        }
        
        var nearByCities = [City]()
        
        for city in data {
            let row = Row.init(city, in: test?.context)
            let foundPlace = try City.init(row: row)
            nearByCities.append(foundPlace)
        }
        
        return nearByCities.first
    }
    
}

extension Destination : Commentable {
    
}
extension Destination: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(name: try json.get("name"),
                  startDate: try json.get("startDate"),
                  endDate: try json.get("endDate"),
                  longitude: try json.get("longitude"),
                  latitude: try json.get("latitude"),
                  createdBy: try json.get("createdBy"),
                  relatedObject: try json.get("relatedObject"),
                  relatedObjectId: try json.get("relatedObjectId"))
        self.id = try json.get("id")
    }
    
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("name", name)
        try json.set("startDate", startDate)
        try json.set("endDate", endDate)
        try json.set("longitude", longitude)
        try json.set("latitude", latitude)
        try json.set("createdBy", createdBy)
        try json.set("relatedObject", relatedObject)
        try json.set("relatedObjectId", relatedObjectId)
        try json.set("places", try places.all().makeJSON())
        return json
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

extension Destination : Rateable { }
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
