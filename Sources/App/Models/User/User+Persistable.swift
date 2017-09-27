//
//  User+Persistable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-21.
//

import Vapor
import Sessions
import HTTP
import AuthProvider

struct sessionCacheStruct {
    var user : User
    var timestamp : Double
    
    init( user: User, timestamp: Double){
        self.user = user
        self.timestamp = timestamp
    }
}

extension User: SessionPersistable {
    
    static var sessionCache = [String : sessionCacheStruct]()
    
    
    public func persist(for req: Request) throws {
        let session = try req.assertSession()
        if session.data["session-entity-id"]?.wrapped != id?.wrapped {
            try req.assertSession().data.set("session-entity-id", id)
            User.sessionCache[String(describing: id!.wrapped.int!)] = sessionCacheStruct(user: self, timestamp: Date().timeIntervalSince1970)
        }
        
    }
    
    public func unpersist(for req: Request) throws {
        let session = try req.assertSession()
        if session.data["session-entity-id"]?.wrapped != id?.wrapped {
            User.sessionCache.removeValue(forKey: String(describing: id!.wrapped.int!))
        }
        try req.assertSession().data.removeKey("session-entity-id")
    }
    
    public static func fetchPersisted(for request: Request) throws -> User? {
        guard let id = try request.assertSession().data["session-entity-id"] else {
            return nil
        }
        
        if let sessionStruct = User.sessionCache[String(describing: id.wrapped.int!)] {
            return sessionStruct.user
        }else {
            guard let user = try User.find(id) else {
                return nil
            }
            
            User.sessionCache[String(describing: user.id!.wrapped.int!)] = sessionCacheStruct(user: user, timestamp: Date().timeIntervalSince1970)
            return user
        }
    }
}

extension Request {
    func user() throws -> User {
        return try auth.assertAuthenticated()
    }
}
