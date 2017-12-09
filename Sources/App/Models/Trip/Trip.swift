//
//  Trip.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-20.
//

import Vapor
import FluentProvider


final class Trip {
    var storage = Storage()
    
    var attendees: Siblings<Trip, User, Pivot<Trip, User>> {
        return siblings()
    }
    
    var destinations : [Destination] {
        get {
           guard let destinations = try? Destination.makeQuery().and({ andGroup in
                try andGroup.filter("relatedObjectId", .equals, objectIdentifier)
                try andGroup.filter("relatedObject", .equals, objectType)
                
           }).all() else {
             return [Destination]()
            }
            
            return destinations
        }
    }
    var places : [Place] {
        get {
            guard let places = try? Place.makeQuery().and({ andGroup in
                try andGroup.filter("relatedObjectId", .equals, objectIdentifier)
                try andGroup.filter("relatedObject", .equals, objectType)
                
            }).all() else {
                return [Place]()
            }
            
            return places
        }
    }
    
//    var routes : [Route] {
//        get {
//            
//        }
//    }
    
    var tripStart : Double?
    var tripEnd : Double?
    var name : String
    var _coverPhoto : Identifier?
    var cover : File {
        get {
            guard let fileId = self._coverPhoto else {
                let workDir = Config.workingDirectory()
                let file = File.init(name: "defaultTripCover", path: "/img/mapmarker.png", absolutePath: "\(workDir)public/img/mapmarker.png", user_id: self.id!, type: .image)
                return file
            }
            guard let file = try? File.find(fileId)! else {
                let workDir = Config.workingDirectory()
                let file = File.init(name: "defaultTripCover", path: "/img/mapmarker.png", absolutePath: "\(workDir)public/img/mapmarker.png", user_id: self.id!, type: .image)
                return file
            }
            
            return file
        }
    }
    var tripDescription : String = ""
    var createdBy : Identifier
    var publicTrip : Bool = false
    
    
    static func createTrip(name _name : String, tripStart _start : Double, tripEnd _end : Double, createdBy _createdBy : Identifier, description _desc : String = "") throws -> Trip {
        
        let trip = try Trip.init(name: _name, tripStart: _start, tripEnd: _end, createdBy: _createdBy,description : _desc)
        let user = try User.find(_createdBy)!
        try trip.save()
        try trip.attendees.add(user)
        try trip.save()
        
        try Feed.createNewFeed(createdBy: _createdBy,
                               feedText: "<a href=\"\(user.getURL())\">\(user.username) created a new trip",
                               feedObject: trip.objectType,
                               feedObjectId: trip.objectIdentifier,
                               feedType: .tripCreated,
                               targetId: trip.id!)
        
        return trip
    }
    
    init(name _name : String, tripStart _start : Double, tripEnd _end : Double, createdBy _createdBy : Identifier, description _desc : String = "") throws{
        self.name = _name
        self.tripStart = _start
        self.tripEnd = _end
        self.createdBy = _createdBy
        self.tripDescription = _desc
    }
    
    init() {
        name = ""
        createdBy = 0
    }
    
    init(name _name : String, createdBy _createdBy : Identifier) {
        self.name = _name
        self.createdBy = _createdBy
    }
    
    func getURL()->String{
        return "/trip/\(self.id!.int!)"
    }
    
    static func getTripsFor(user _user: Identifier) throws -> [Trip] {
        var trips = [Trip]()
        
        guard let trip = try? Trip.makeQuery().filter("createdBy", .equals, _user).all() else {
            return trips
        }
        trips.append(contentsOf: trip)
        return trips
    }
    //MARK: ATTENDANTS
    
    //TODO: TODO UPDATE AFTER METHOD EXISTS
    //TODO: TODO ADD NOTIFICATIONS TO ALL METHODS
    func inviteAttendant(attendant _att: User) {
        
    }
    
    func addNewAttendant(attendant _att : User) throws {
        try self.attendees.add(_att)
    }
    
    func removeAttendant(attendant _att: User) throws {
        try self.attendees.remove(_att)
    }
    
    
    //MARK: DESTINATIONS
    
    //TODO: TODO ADD NOTIFICATIONS TO ALL METHODS
//    func addDestination(destination _dest: Destination){
//        self.destinations.append(_dest)
//    }
//
//    func removeDestination(destination _dest: Destination){
//        if let i = self.destinations.index(where: {$0.id == _dest.id}){
//            self.destinations.remove(at: i)
//        }
//    }
    
    
}
