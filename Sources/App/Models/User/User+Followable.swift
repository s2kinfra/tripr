//
//  User+Followable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-26.
//

extension User : Followable {
    
    func getFollowedTrips() throws -> [Trip] {
        var trips = [Trip]()
        
        for follow in self.following {
            if follow.object == Trip.objectType {
                trips.append((try Trip.find(follow.objectId))!)
            }
        }
       
        return trips
        
    }
}
