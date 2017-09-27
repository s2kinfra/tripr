//
//  Destination.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-20.
//

import Vapor
import FluentProvider

final class Destination : Model, Attachable {
    
    var storage: Storage = Storage()
    
    var name : String?
    var startDate : Date?
    var endDate : Date?
    var longitude : Double?
    var latitude : Double?
    var Place : Place?
    
    required init(row: Row) throws {
        name = try row.get("name")
    
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        return row
    }
    
    var objectIdentifier: Identifier{
        get{
            return self.id!
        }
    }
    
}

extension Destination: Timestampable { }
