//
//  Feed.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-30.
//

import Foundation
import Vapor
import FluentProvider

let feedNotificationKey = "se.fabularis.feeds"

enum FeedType : Int {
    case followAccepted = 1,
         followDeclined = 2,
         followRequest = 3,
         tripCreated = 10,
         tripFollowed = 11,
         commentAdded = 20,
         photoAdded = 30,
         unknown = 9999
}

final class Feed : Model {
    var storage: Storage = Storage()
    
    var createdBy : Identifier
    var timestamp : Double
    var feedText : String
    var feedType : Int
    var feedObject : String
    var feedObjectId : Identifier
    var targetId : Identifier
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("createdBy", createdBy)
        try row.set("feedObject", feedObject)
        try row.set("feedObjectId", feedObjectId)
        try row.set("feedText", feedText)
        try row.set("timestamp", timestamp)
        try row.set("feedType", feedType)
        try row.set("targetId", targetId)
        try row.set("id", id)
        return row
    }
    
    init(createdBy _createdBy : Identifier, feedType _type : Int, feedText _text : String, feedObject _object: String , feedObjectId _objectId : Identifier, timestamp _time : Double, targetId _targetId: Identifier ) {
        self.createdBy = _createdBy
        self.feedText = _text
        self.feedObject = _object
        self.feedObjectId = _objectId
        self.timestamp = _time
        self.feedType = _type
        self.targetId = _targetId
    }
    
    required init(row: Row) throws {
        createdBy = try row.get("createdBy")
        timestamp = try row.get("timestamp")
        feedText = try row.get("feedText")
        feedType = try row.get("feedType")
        feedObject = try row.get("feedObject")
        feedObjectId = try row.get("feedObjectId")
        targetId = try row.get("targetId")
        id = try row.get(idKey)
    }
    
    static func createNewFeed(createdBy _createdBy : Identifier, feedText _text : String, feedObject _object: String , feedObjectId _objectId : Identifier, feedType _type: FeedType, targetId _targetId : Identifier ) throws
    {
        let feed = Feed.init(createdBy: _createdBy, feedType: _type.rawValue, feedText: _text, feedObject: _object, feedObjectId: _objectId, timestamp: Date().timeIntervalSince1970, targetId: _targetId)
        try feed.save()
    }
//    static func createFeedEntry(feed _feed : Feed) {
//        background {
//            do {
//                let feed = FeedHandler.init(feed: _feed)
//                try feed.save()
//            }catch {
//                print("error creating feed")
//            }
//        }
//    }
}

extension Feed: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(createdBy: try json.get("createdBy"),
                  feedType: try json.get("feedType"),
                  feedText: try json.get("feedText"),
                  feedObject: try json.get("feedObject"),
                  feedObjectId: try json.get("feedObjectId"),
                  timestamp: try json.get("timestamp"),
                  targetId: try json.get("targetId"))
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("createdBy", createdBy)
        try json.set("feedType", feedType)
        try json.set("id", id)
        try json.set("feedText", feedText)
        try json.set("feedObject", feedObject)
        try json.set("feedObjectId", feedObjectId)
        try json.set("timestamp", timestamp)
        try json.set("comments", comments)
        try json.set("envies", envies)
        try json.set("targetId", targetId)
        return json
    }
}

extension Feed : Timestampable {}

extension Feed : Envyable {
    func getCreators() -> [Identifier] {
        return [self.createdBy]
    }
}
extension Feed: Commentable {
    var objectIdentifier: Identifier {
        return id!
    }
}

extension Feed : Parameterizable {
    /// the unique key to use as a slug in route building
    public static var uniqueSlug: String {
        return "id"
    }
    
    // returns the found model for the resolved url parameter
    public static func make(for parameter: String) throws -> Feed {
        guard let found = try Feed.find(parameter) else {
            throw Abort(.notFound, reason: "No \(Feed.self) with that identifier was found.")
        }
        return found
    }
}

extension Feed: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Posts
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("feedText")
            builder.string("feedObject")
            builder.int("feedObjectId")
            builder.foreignId(for: User.self, optional: false, unique: false, foreignIdKey: "createdBy", foreignKeyName: "feed_createdBy")
            builder.double("timestamp")
            builder.int("feedType")
            builder.int("targetId")
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}


