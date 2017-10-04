//
//  User+JSONConvertable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-27.
//

import Foundation
extension User: JSONConvertible {
    convenience init(json: JSON) throws {
     self.init(username: try json.get("username"),
               email: try json.get("email"),
               password: try json.get("password"))
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("username", username)
        try json.set("email", email)
//        try json.set(Post.idKey, id)
//        try json.set(Post.contentKey, content)
        return json
    }
}

// MARK: HTTP

// This allows Post models to be returned
// directly in route closures
extension User: ResponseRepresentable { }
