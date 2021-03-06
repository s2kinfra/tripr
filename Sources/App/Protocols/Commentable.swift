//
//  Comment.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-21.
//

import Vapor

protocol Commentable : ObjectIdentifiable {
    
    var comments : [Comment] {get}
    func addComment(by: Identifier, commment _comment: String) throws -> Comment
    func removeComment(comment : Comment) throws
}

extension Commentable {
    
    var comments : [Comment] {
        get {
            guard let comments = try? Comment.makeQuery().and( { andGroup in
                try andGroup.filter("commentedObject" , .equals, objectType)
                try andGroup.filter("commentedObjectId", .equals, objectIdentifier)
            }).all() else {
                return [Comment]()
            }
            return comments
        }
    }
    
    func addComment(by: Identifier, commment _comment: String) throws -> Comment{
        let comment = Comment.init(text: _comment, writtenBy: by, commentedObject: objectType, commentedObjectId: objectIdentifier)
        try comment.save()
        return comment
    }
    
    func removeComment(comment : Comment) throws {
        try comment.delete()
    }
    
}
