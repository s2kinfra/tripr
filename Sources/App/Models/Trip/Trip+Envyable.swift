//
//  Trip+Envyable.swift
//  tripr2PackageDescription
//
//  Created by Daniel Skevarp on 2017-09-21.
//

import Vapor

extension Trip : Envyable {
    var objectIdentifier: Identifier {
        return self.id!
    }
    
    func getCreators() -> [Identifier] {
        var creators = [Identifier]()
        do {
            for user in try attendees.all(){
                creators.append(user.id!)
            }
        }catch{
            
        }
        return creators
    }
    
    //    TODO : NOT REALLY SURE
    
}

extension Trip: Commentable {
    
    func addComment(by: Identifier, commment _comment: String, createFeed _feed : Bool) throws {
        let comment = try self.addComment(by: by, commment: _comment)
        if _feed {
            try Feed.createNewFeed(createdBy: by, feedText: "comment to trip", feedObject: self.objectType, feedObjectId: self.objectIdentifier, feedType: .commentAdded, targetId: comment.id!)
        }
    }
}
