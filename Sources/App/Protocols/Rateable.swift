//
//  Rateable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-11-16.
//

import Foundation
import Vapor
import FluentProvider


protocol Rateable : ObjectIdentifiable{
    var ratings : [Rating] {get}
    func setRating( rating : Int , by : Identifier) throws
}

extension Rateable {
    
    var ratings : [Rating] {
        get {
            guard let ratings = try? Rating.makeQuery().and( { andGroup in
                try andGroup.filter("ratedObject" , .equals, objectType)
                try andGroup.filter("ratedObjectId", .equals, objectIdentifier)
            }).all() else {
                return [Rating]()
            }
            return ratings
        }
    }
    
    func setRating(rating : Int, by : Identifier) throws {
        let rating = Rating.init(ratedObject: objectType, ratedObjectId: objectIdentifier, ratedBy: by, rating: rating)
        try rating.save()
    }
}

