//
//  Followable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-26.
//

import Foundation
import Vapor
import FluentProvider

protocol Followable : ObjectIdentifiable{
    var followers : [Follow] {get}
    var following : [Follow] {get}
    func startFollowing(by : Identifier) throws
    func stopFollowing(by : Identifier) throws
    func acceptFollow(follower: Identifier) throws
    func declineFollow(follower: Identifier) throws
    
}
extension Followable {
    
    var followers : [Follow] {
        get{
            do {
                let follower = try Follow.makeQuery().and { andGroup in
                    try andGroup.filter("object", .equals, self.objectType)
                    try andGroup.filter("objectId", .equals, self.objectIdentifier)
                    try andGroup.filter("accepted", .equals, true)
                    }.all()
                return follower
            }catch {
                return [Follow]()
            }
        }
    }
    
    var following : [Follow] {
        get {
            do {
                let following = try Follow.makeQuery().and { andGroup in
                    try andGroup.filter("object", .equals, objectType)
                    try andGroup.filter("follower", .equals, objectIdentifier)
                    try andGroup.filter("accepted", .equals, true)
                    }.all()
                return following
            }catch {
                return [Follow]()
            }
        }
    }
    
    func startFollowing(by : Identifier) throws {
        let follow = Follow.init(object: objectType, objectId: objectIdentifier, follower: by)
        try follow.save()
    }
    
    func stopFollowing(by : Identifier) throws {
        guard let follow = try Follow.makeQuery().and({ andGroup in
            try andGroup.filter("object", .equals, objectType)
            try andGroup.filter("objectId", .equals, objectIdentifier)
            try andGroup.filter("follower", .equals, by)
            try andGroup.filter("accepted", .equals, true)
        }).first() else {
            //            TODO: throw!
            return
        }
        try follow.delete()
    }
    
    func acceptFollow(follower: Identifier) throws {
        guard let follow = try Follow.makeQuery().and({ andGroup in
            try andGroup.filter("object", .equals, objectType)
            try andGroup.filter("objectId", .equals, objectIdentifier)
            try andGroup.filter("follower", .equals, follower)
            try andGroup.filter("accepted", .equals, false)
        }).first() else {
            //            TODO: throw!
            let error = Abort.init(.badRequest, metadata: follower.makeNode(in: nil), reason: "Follow request not found")
            throw error
        }
        follow.accpeted = true
        try follow.save()
    }
    
    func declineFollow(follower: Identifier) throws {
        guard let follow = try Follow.makeQuery().and({ andGroup in
            try andGroup.filter("object", .equals, objectType)
            try andGroup.filter("objectId", .equals, objectIdentifier)
            try andGroup.filter("follower", .equals, follower)
            try andGroup.filter("accepted", .equals, false)
        }).first() else {
            //            TODO: throw!
            let error = Abort.init(.badRequest, metadata: follower.makeNode(in: nil), reason: "Follow request not found")
            throw error
        }
        try follow.delete()
    }
}

