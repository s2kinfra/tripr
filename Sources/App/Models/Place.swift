//
//  Place.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-20.
//

import Foundation
import Vapor
import FluentProvider
import MapKit

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
    var destination_id : Identifier?
    var POI_id : Identifier?
    var _photo : Identifier?
    
    var destination : Parent<Place,Destination> {
        return parent(id: destination_id)
    }
    
    var poi : POI? {
        get {
            guard let poi_id = self.POI_id else {
                return nil
            }
            
            guard let poi = try? POI.find(poi_id)! else {
                return nil
            }
            return poi
        }
    }
    var photo : File? {
        get {
            guard let fileid = self._photo else {
                return nil
            }
            guard let file = try? File.find(fileid)! else {
                return nil
            }
            
            return file
        }
    }
    
    init(longitude _long : Double , latitude _lat : Double, name _name : String, createdBy _createdBy : Identifier, poi_id _poi : Identifier, photo _photo : Identifier = nil ) {
        longitude = _long
        latitude = _lat
        name = _name
        createdBy = _createdBy
        POI_id = _poi
        self._photo = _photo
    }
    
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
        try row.set("POI", POI_id)
        try row.set("photo", _photo)
        try row.set("destination_id", destination_id)
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
        destination_id = try row.get("destination_id")
        POI_id = try row.get("POI")
        _photo = try row.get("photo")
    }
    
}

extension Place : Commentable {
    
}
extension Place: JSONConvertible {
    convenience init(json: JSON) throws {
         self.init(longitude: try json.get("longitude"),
                      latitude: try json.get("latitude"),
                      name: try json.get("name"),
                      createdBy: try json.get("createdBy"),
                      poi_id: try json.get("POI_id"),
                      photo: try json.get("photo")
        )
    }
    
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("longitude", longitude)
        try json.set("latitude", latitude)
        try json.set("id", id)
        try json.set("name", name)
        try json.set("createdBy", createdBy)
        try json.set("country", country)
        try json.set("city", city)
        try json.set("comments", try comments.makeJSON())
        try json.set("POI_id", POI_id)
        try json.set("relatedObjectId", relatedObjectId)
        try json.set("relatedObject", relatedObject)
        try json.set("photo", _photo)
        try json.set("poi", poi)
        try json.set("destination", try destination.get()?.makeJSON())
        return json
    }
}

extension Place: Rateable { }

extension Place: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("name")
            builder.double("longitude")
            builder.double("latitude")
            builder.string("country", optional: true, unique: false)
            builder.string("city", optional: true, unique: false)
            builder.string("relatedObject", optional: true, unique: false)
            builder.string("relatedObjectId", optional: true, unique: false)
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "createdBy", foreignKeyName: "place_createdBy")
            builder.foreignId(for: POI.self, optional: true, unique: false, foreignIdKey: "POI", foreignKeyName: "place_POI")
            builder.foreignId(for: File.self, optional: true, unique: false, foreignIdKey: "photo", foreignKeyName: "place_photo")
            builder.parent(Destination.self, optional: true, unique: false, foreignIdKey: Destination.idKey)
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
    func addAttachment(file _file: File, createFeed _feed: Bool) throws -> Attachment{
        let attachment = Attachment.init(file: _file.id!, object: self.objectType, objectId: self.objectIdentifier)
        try attachment.save()
        
        if _feed {
            try Feed.createNewFeed(createdBy: _file.uploadedBy, feedText: "attachment to place", feedObject: self.objectType, feedObjectId: self.objectIdentifier, feedType: .photoAdded , targetId: _file.id!)
        }
        return attachment
    }
}
extension Place: Suggestable { }
extension Place: Timestampable { }


