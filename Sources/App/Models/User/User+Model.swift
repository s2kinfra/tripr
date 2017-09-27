//
//  User+Model.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-21.
//

import Foundation
import Vapor
import FluentProvider

extension User : Model {

    
    convenience init(row: Row) throws {
        self.init()
        username = try row.get("username")
        email = try row.get("email")
        let passwordAsString: String = try row.get("password")
        password = passwordAsString.makeBytes()
        id = try row.get(idKey)
    }
    
    // Serializes the Post to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("username", username)
        try row.set("email", email)
        try row.set("password", password.makeString())
        try row.set("id", id)
        return row
    }
}

extension User : Parameterizable {
    /// the unique key to use as a slug in route building
    public static var uniqueSlug: String {
        return "username"
    }
    
    // returns the found model for the resolved url parameter
    public static func make(for parameter: String) throws -> User {
        guard let found = try User.makeQuery().filter(User.self, .compare("username", .equals, parameter.makeNode(in: nil))).first() else {
            throw Abort(.notFound, reason: "No \(User.self) with that identifier was found.")
        }
        return found
    }
}



// MARK: Fluent Preparation
extension User: Timestampable { }

extension User: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("username", optional: false, unique: true)
            builder.string("email", optional: false, unique: true)
            builder.bytes("password", optional : false, unique: false)
        }
        try database.index("username", for: User.self)
        try database.index("email", for: User.self)
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
