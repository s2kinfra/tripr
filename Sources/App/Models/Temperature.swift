//
//  Temperature.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-27.
//

import Foundation
import Vapor
import FluentProvider

final class Temperature : Model {
    var storage: Storage = Storage()
    
    let object : String
    let objectId : Identifier
    let temperature : Double
    let timestamp : Double
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("object", object)
        try row.set("objectId", objectId)
        try row.set("temperature", temperature)
        try row.set("timestamp", timestamp)
        return row
    }
    
    init(row: Row) throws {
        object = try row.get("object")
        objectId = try row.get("objectId")
        temperature = try row.get("temperature")
        timestamp = try row.get("timestamp")
    }
    
    init(object _object : String, objectId _objectId: Identifier, timestamp _time : Double = Date().timeIntervalSince1970, temperature _temp : Double = -99)
    {
        object = _object
        objectId = _objectId
        timestamp = _time
        temperature = Double()
    }
    
    
    
    
}

extension Temperature : Timestampable {}
