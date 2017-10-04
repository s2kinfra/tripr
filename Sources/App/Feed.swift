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


protocol Feedable {
    func getFeedObjects() throws ->[Feed]
    
}

final class FeedHandler : Model {
    var storage: Storage = Storage()
    
    var feed : Feed
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("createdBy", feed.createdBy)
        try row.set("feedObject", feed.feedObject)
        try row.set("feedObjectId", feed.feedObjectId)
        try row.set("feedText", feed.feedText)
        try row.set("timestamp", feed.timestamp)
        return row
    }
    
    init(feed _feed : Feed) {
        feed = _feed
    }
    
    required init(row: Row) throws {
        let feed = Feed.init(createdBy: try row.get("createdBy"),
                             timestamp: try row.get("timestamp"),
                             feedText: try row.get("feedText"),
                             feedObject: try row.get("feedObject"),
                             feedObjectId: try row.get("feedObjectId"))
        self.feed = feed
    }
    
    static func createFeedEntry(feed _feed : Feed) {
        background {
            do {
                let feed = FeedHandler.init(feed: _feed)
                try feed.save()
            }catch {
                print("error creating feed")
            }
        }
    }
}

extension FeedHandler : Timestampable {}
extension FeedHandler: Preparation {
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
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
struct Feed {
    
    var createdBy : Identifier
    var timestamp : Double
    var feedText : String
    var feedObject : String
    var feedObjectId : Identifier
    
}


