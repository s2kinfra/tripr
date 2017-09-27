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
    
    var attendees = [User]()
    var destinations = [Destination]()
    var places : [Place]?
    var routes : [Route]?
    var tripStart : Date?
    var tripEnd : Date?
    var name : String
    var coverPhoto : File?
    var tripDescription : String?
    var createdBy : Identifier
    
    
    init(name _name : String, tripStart _start : Date, tripEnd _end : Date, createdBy _createdBy : Identifier) throws{
        self.name = _name
        self.tripStart = _start
        self.tripEnd = _end
        self.createdBy = _createdBy
        let creator = try User.find(_createdBy)
        self.attendees.append(creator!)
    }
    
    init() {
        name = ""
        createdBy = 0
    }
    
    init(name _name : String, createdBy _createdBy : Identifier) {
        self.name = _name
        self.createdBy = _createdBy
    }
    
    
    //MARK: ATTENDANTS
    
    //TODO: TODO UPDATE AFTER METHOD EXISTS
    //TODO: TODO ADD NOTIFICATIONS TO ALL METHODS
    func inviteAttendant(attendant _att: User) {
        
    }
    
    func addNewAttendant(attendant _att : User) {
        self.attendees.append(_att)
    }
    
    func removeAttendant(attendant _att: User) {
        if let i = self.attendees.index(where: {$0.id == _att.id}){
            self.attendees.remove(at: i)
        }
    }
    
    
    //MARK: DESTINATIONS
    
    //TODO: TODO ADD NOTIFICATIONS TO ALL METHODS
    func addDestination(destination _dest: Destination){
        self.destinations.append(_dest)
    }
    
    func removeDestination(destination _dest: Destination){
        if let i = self.destinations.index(where: {$0.id == _dest.id}){
            self.destinations.remove(at: i)
        }
    }
    
    
}
