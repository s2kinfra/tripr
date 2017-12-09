//
//  POI.swift
//  App
//
//  Created by Daniel Skevarp on 2017-11-02.
//
import Foundation
import Vapor
import FluentProvider
import MapKit
import CoreLocation

struct POI_geometry : Codable {
    var location : POI_location
}
struct POI_location : Codable {
    var lat : Double
    var lng : Double
}
struct POI_DATA : Codable {
    var geometry : POI_geometry
    var name : String
    var place_id : String
    var vicinity : String?
    var types : [String]
}
struct POI_RESULT : Codable{
    
    var results : [POI_DATA]
    
}


final class POI : Model{
    var storage: Storage = Storage()
    var longitude : Double
    var latitude : Double
    var name : String
    var placeId : String
    var vicinity : String?
    var createdBy : Identifier?
    
    init(longitude _long : Double , latitude _lat : Double, name _name : String, createdBy _createdBy : Identifier, placeId _id : String, vicinity _vic : String) {
        longitude = _long
        latitude = _lat
        name = _name
        createdBy = _createdBy
        vicinity = _vic
        placeId = _id
        
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("longitude" , longitude)
        try row.set("latitude", latitude)
        try row.set("name", name)
        try row.set("vicinity", vicinity)
        try row.set("createdBy", createdBy)
        try row.set("placeId", placeId)
        return row
    }
    
    init(row: Row) throws {
        longitude = try row.get("longitude")
        latitude = try row.get("latitude")
        name = try row.get("name")
        vicinity = try row.get("vicinity")
        createdBy = try row.get("createdBy")
        placeId = try row.get("placeId")
    }
    
    init(fromAPI _api : POI_DATA, by : Identifier?) throws {
        longitude = _api.geometry.location.lng
        latitude = _api.geometry.location.lat
        name = _api.name
        vicinity = _api.vicinity
        createdBy = by
        placeId = _api.place_id
    }
    
    static func getPOIFrom(placeId _placeId : String) throws -> POI {
        
        guard let poi = try? POI.makeQuery().filter("placeId", .equals, _placeId).first() else {
            throw Error.customString(message: "POI not found")
        }
        
        if poi == nil {
            throw Error.customString(message: "POI not found")
        }
        
        return poi!
        
    }
    
    static func createPOI(fromFile _file: File) throws {
        let url = NSURL(string: "http://localhost:8080\(_file.path)")
        let imageSource = CGImageSourceCreateWithURL(url!, nil)
        let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil)! as NSDictionary;
        
        let exifDict = imageProperties.value(forKey: "{GPS}")  as! NSDictionary;
        
        var _lat : Double = 0.0
        var _long : Double = 0.0
        var _longRef = ""
        var _latRef = ""
        
        for (k,v) in exifDict {
            print(k , v)
            switch k as! String{
            case "Latitude" :
                _lat = v as! Double
            case "Longitude" :
                _long = v as! Double
            case "LatitudeRef" :
                _latRef = v as! String
            case "LongitudeRef" :
                _longRef = v as! String
            default: break
            }
        }
        
        if _longRef == "W" {
            _long = _long * -1
        }
        if _latRef == "S" {
            _lat = _lat * -1
        }
        
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(_lat),\(_long)&radius=50000&key=AIzaSyAknKg8MG0bW9uzXrUJC88fx0U480P3ctI"
        print(urlString)
        let url2 = URL(string: urlString)
        URLSession.shared.dataTask(with:url2!) { (data, response, error) in
            if error != nil {
                print(error ?? "")
            } else {
                
                guard let responseData = data else {
                    print("Error: did not receive data")
                    return
                }
                
                let decoder = JSONDecoder()
                do {
                    
                    let pois = try decoder.decode(POI_RESULT.self, from: responseData)
                    for poi in pois.results {
                        let newPOI = try POI.init(fromAPI: poi , by: _file.uploadedBy)
                        try newPOI.save()
                    }
                } catch {
                    print("error trying to convert data to JSON")
                    print(error)
                }
            }
            
            }.resume()
    }
    
    
    func getNearByPOIs(distance _dist : Int) throws -> [POI] {
        let test = try POI.database?.raw("SELECT *, ( 6371 * acos( cos( radians( \(self.latitude) ) ) * cos( radians( `latitude` ) ) * cos( radians( `longitude` ) - radians( \(self.longitude) ) ) + sin(radians(\(self.latitude))) * sin(radians(`latitude`)) ) ) `distance` FROM `p_o_is` HAVING `distance` < \(_dist) ORDER BY `distance`  LIMIT 50")
        
        guard let data = test?.wrapped.array else {
            return [POI]()
        }
        
        var nearByPlaces = [POI]()
        
        for place in data {
            let row = Row.init(place, in: test?.context)
            let foundPlace = try POI.init(row: row)
            nearByPlaces.append(foundPlace)
        }
        
        return nearByPlaces
    }
    
    
    private static func dlPlaces(longitude _long : Double, latitude _lat : Double, createdBy _created : Identifier, distance _dist : Int) throws  {
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(_lat),\(_long)&radius=\(_dist)&key=AIzaSyAknKg8MG0bW9uzXrUJC88fx0U480P3ctI"
        let url2 = URL(string: urlString)
        URLSession.shared.dataTask(with:url2!) { (data, response, error) in
            if error != nil {
                print(error ?? "")
            } else {
                
                guard let responseData = data else {
                    print("Error: did not receive data")
                    return
                }
                
                let decoder = JSONDecoder()
                do {
                    
                    let pois = try decoder.decode(POI_RESULT.self, from: responseData)
                    for poi in pois.results {
                        let place = try POI.init(fromAPI: poi, by: _created)
                        do {
                            try place.save()
                        }catch {
                        }
                    }
                } catch {
                    print("error trying to convert data to JSON")
                    print(error)
                }
            }
            
            }.resume()
    }
    
    static func downloadPlacesFor(longitude _long : Double, latitude _lat : Double, createdBy _created : Identifier) throws  {
        try POI.dlPlaces(longitude: _long, latitude: _lat, createdBy: _created, distance: 5000)
        try POI.dlPlaces(longitude: _long, latitude: _lat, createdBy: _created, distance: 1000)
        try POI.dlPlaces(longitude: _long, latitude: _lat, createdBy: _created, distance: 500)
        try POI.dlPlaces(longitude: _long, latitude: _lat, createdBy: _created, distance: 100)
        try POI.dlPlaces(longitude: _long, latitude: _lat, createdBy: _created, distance: 20)
        
    }
    static func getNearByPlaces( longitude _long: Double, latitude _lat : Double, distance _dist: Int) throws -> [POI]
    {
        
        let test = try POI.database?.raw("SELECT *, ( 6371 * acos( cos( radians( \(_lat) ) ) * cos( radians( `latitude` ) ) * cos( radians( `longitude` ) - radians( \(_long) ) ) + sin(radians(\(_lat))) * sin(radians(`latitude`)) ) ) `distance` FROM `p_o_is` HAVING `distance` < \(_dist) ORDER BY `distance`  LIMIT 50")
        
        guard let data = test?.wrapped.array else {
            return [POI]()
        }
        
        var nearByPlaces = [POI]()
        
        for place in data {
            let row = Row.init(place, in: test?.context)
            let foundPlace = try POI.init(row: row)
            nearByPlaces.append(foundPlace)
        }
        
        return nearByPlaces
    }
    
    static func getNearByPlaces(place _place: Place, distance _dist : Int) throws -> [POI] {
        let test = try POI.database?.raw("SELECT *, ( 6371 * acos( cos( radians( \(_place.latitude) ) ) * cos( radians( `latitude` ) ) * cos( radians( `longitude` ) - radians( \(_place.longitude) ) ) + sin(radians(\(_place.latitude))) * sin(radians(`latitude`)) ) ) `distance` FROM `p_o_is` HAVING `distance` < \(_dist) ORDER BY `distance`  LIMIT 50")
        
        guard let data = test?.wrapped.array else {
            return [POI]()
        }
        
        
        var nearByPlaces = [POI]()
        
        for place in data {
            let row = Row.init(place, in: test?.context)
            let foundPlace = try POI.init(row: row)
            nearByPlaces.append(foundPlace)
        }
        
        return nearByPlaces
    }
}

extension POI: Rateable {
    var objectIdentifier: Identifier {
        return self.id!
    }
}

extension POI: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("placeId", optional: false, unique: true)
            builder.string("name")
            builder.double("longitude")
            builder.double("latitude")
            builder.string("vicinity", optional: true, unique: false)
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "createdBy", foreignKeyName: "poi_createdBy")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension POI: Timestampable { }


extension POI: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(longitude: try json.get("longitude"),
                  latitude: try json.get("latitude"),
                  name: try json.get("name"),
                  createdBy: try json.get("createdBy"),
                  placeId: try json.get("placeId"),
                  vicinity: try json.get("vicinity")
        )
        self.id = try json.get("id")
    }
    
    
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("name", name)
        try json.set("longitude", longitude)
        try json.set("id", id)
        try json.set("latitude", latitude)
        try json.set("placeId", placeId)
        try json.set("vicinity", vicinity)
        try json.set("createdBy", createdBy)
        return json
    }
}



