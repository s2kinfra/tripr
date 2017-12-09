//
//  Trip+Followable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-26.
//

import Foundation

extension Trip : Followable {
    
    
}

extension Trip : Rateable { }
extension Trip : Feedable {
    func getFeedObjects(limit _limit: Int) throws -> [Feed] {
        var following = [Identifier]()
        for follow in try self.attendees.all() {
            following.append(follow.id!)
        }
        following.append(self.id!)
//        let feed = try self.fetchFeedObjects(createdBy: following limit: _limit)
        let feed = try self.fetchFeedObjects(createdBy: following, objectType: self.objectType, objectId: self.objectIdentifier, limit: _limit)
        return feed
    }
    
    
}

extension Trip : Attachable {
    func addAttachment(file _file: File, createFeed _feed: Bool) throws -> Attachment{
        let attachment = Attachment.init(file: _file.id!, object: self.objectType, objectId: self.objectIdentifier)
        try attachment.save()
        
        if _feed {
            try Feed.createNewFeed(createdBy: _file.uploadedBy, feedText: "attachment to trip", feedObject: self.objectType, feedObjectId: self.objectIdentifier, feedType: .photoAdded , targetId: _file.id!)
        }
        return attachment
    }
    
}
