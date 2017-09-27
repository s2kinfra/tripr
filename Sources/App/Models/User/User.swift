//
//  User.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-20.
//

import Vapor
import FluentProvider

final class User {
    var storage = Storage()
    
    var username: String = ""
    var email : String = ""
    var password : Bytes
    var profilePicture : File?
    
    
    init() {
        password = []
    }
    
}

extension User : Envyable {
    var objectIdentifier: Identifier {
        return self.id!
    }
    
    func getCreators() -> [Identifier] {
        var creators = [Identifier]()
        creators.append(self.id!)
        return creators
    }
}
