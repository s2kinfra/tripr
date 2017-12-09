//
//  User+Feedable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-30.
//

import Foundation

extension User: Feedable {
    
    func getFeedObjects(limit _limit : Int = 20) throws -> [Feed] {
        var following = [Identifier]()
        for follow in self.following {
            following.append(follow.objectId)
        }
        following.append(self.id!)
//        let feed = try self.fetchFeedObjects(createdBy: following, limit: _limit)
        let feed = try self.fetchFeedObjects(createdBy: following, feedTypes: [.tripCreated, .followAccepted, .followRequest, .followDeclined], limit: _limit)
        return feed
    }
}


