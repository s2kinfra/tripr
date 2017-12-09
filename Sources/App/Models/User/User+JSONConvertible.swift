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
               password: try json.get("password"),
               profilePicture : try json.get("profilePicture"),
               firstName : try json.get("firstName"),
               lastName : try json.get("lastName")
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("username", username)
        try json.set("email", email)
        try json.set("id", id)
        try json.set("firstName", firstName)
        try json.set("lastName", lastName)
        try json.set("profilePicture", try profilePicture.makeJSON())
        try json.set("profileCover", try profileCover.makeJSON())
        try json.set("following", following)
        try json.set("followers", followers)
        try json.set("followingRequests", followingRequests)
        try json.set("followerRequests", followerRequest)
        try json.set("feeds", feeds)
        try json.set("fullname", fullname)
        try json.set("notifications", notifications)
        try json.set("unreadNotifications",unreadNotifications)
//        try json.set(Post.idKey, id)
//        try json.set(Post.contentKey, content)
        return json
    }
}

// MARK: HTTP

// This allows Post models to be returned
// directly in route closures
extension User: ResponseRepresentable { }
