//
//  User+Feedable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-30.
//

import Foundation

extension User: Feedable {
    func getFeedObjects() throws -> [Feed] {
        var feed = [Feed]()
        for user in self.following{
            
        }
        
        return feed
    }
}
