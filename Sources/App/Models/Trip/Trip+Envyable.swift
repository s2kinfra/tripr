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
        for user in attendees.enumerated(){
            creators.append(user.element.id!)
        }
        return creators
    }
    
    //    TODO : NOT REALLY SURE
    
}
