//
//  Feedable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-10-11.
//

import Foundation
import Vapor
import FluentProvider


protocol Feedable : ObjectIdentifiable{
    var feeds : [Feed] {get}
    func getFeedObjects(limit _limit : Int) throws ->[Feed]
    func fetchFeedObjects(createdBy _createdBy : [Identifier], limit _limit : Int) throws -> [Feed]
}

extension Feedable {
    
    var feeds : [Feed] {
        get {
            do{
                return try self.getFeedObjects(limit: 20)
            }catch let error{
                //                error handling!
                print(String(describing: error))
                return [Feed]()
            }
        }
    }
    
    func fetchFeedObjects(createdBy _createdBy : [Identifier], objectType _objectType: String, objectId _oid : Identifier, limit _limit : Int = 10) throws -> [Feed] {
        do {
            var feed = try Feed.makeQuery().filter("createdBy", in: _createdBy).filter("feedObject", .equals, _objectType).filter("feedObjectId", .equals, _oid.int!).sort("timestamp", .descending).limit(_limit).all()
            
            feed.append(contentsOf: try Feed.makeQuery().and({andGroup in
                try andGroup.filter("feedObject", .equals, _objectType)
                try andGroup.filter("feedObjectId", .equals, _oid.int!)
            }).distinct().all())
            
            var uniqFeed = [Feed]()
            for (_ , element) in feed.enumerated() {
                if !uniqFeed.contains(where: { feed in
                    feed.id == element.id
                }){
                    uniqFeed.append(element)
                }
            }
            
            uniqFeed.sort(by: { (feed1, feed2) -> Bool in
                return feed1.timestamp > feed2.timestamp
            })
            
            return uniqFeed
        }catch let error{
            print(String(describing: error))
            return [Feed]()
        }
    }
    
    func fetchFeedObjects(createdBy _createdBy : [Identifier],feedTypes _types : [FeedType], limit _limit : Int = 10) throws -> [Feed] {
        do {
            var types = [Int]()
            for type in _types.enumerated(){
                types.append(type.element.rawValue)
            }
            
            let feed = try Feed.makeQuery().filter("createdBy", in: _createdBy).filter("feedType", in: types).sort("timestamp", .descending).limit(_limit).all()
            
            var uniqFeed = [Feed]()
            for (_ , element) in feed.enumerated() {
                if !uniqFeed.contains(where: { feed in
                    feed.id == element.id
                }){
                    uniqFeed.append(element)
                }
            }
            
            uniqFeed.sort(by: { (feed1, feed2) -> Bool in
                return feed1.timestamp > feed2.timestamp
            })
            
            return uniqFeed
        }catch let error{
            print(String(describing: error))
            return [Feed]()
        }
    }
    
    func fetchFeedObjects(createdBy _createdBy : [Identifier], limit _limit : Int = 10) throws -> [Feed] {
        do {
            let feed = try Feed.makeQuery().filter("createdBy", in: _createdBy).sort("timestamp", .descending).limit(_limit).all()
            
            var uniqFeed = [Feed]()
            for (_ , element) in feed.enumerated() {
                if !uniqFeed.contains(where: { feed in
                    feed.id == element.id
                }){
                   uniqFeed.append(element)
                }
            }

            uniqFeed.sort(by: { (feed1, feed2) -> Bool in
                return feed1.timestamp > feed2.timestamp
            })
            
            return uniqFeed
        }catch let error{
            print(String(describing: error))
            return [Feed]()
        }
    }
}

