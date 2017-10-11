//
//  Feedable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-10-11.
//

import Foundation
import Vapor
import FluentProvider


protocol Feedable {
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
    
    func fetchFeedObjects(createdBy _createdBy : [Identifier], limit _limit : Int = 10) throws -> [Feed] {
        do {
            let feed = try Feed.makeQuery().filter("createdBy", in: _createdBy).sort("timestamp", .descending).limit(_limit).all()
            return feed
        }catch let error{
            print(String(describing: error))
            return [Feed]()
        }
    }
}

