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
        tripStart = try row.get("trip_start")
        tripEnd = try row.get("trip_end")
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        //try row.set(User.foreignIdKey, userId)
        try row.set("name", name)
        try row.set("started", tripStart)
        try row.set("ended", tripEnd)
        
        return row
    }
  
    
    
    
    
}
