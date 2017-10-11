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
    var firstName : String = ""
    var lastName : String = ""
    var password : Bytes
    var _profilePicture : Identifier?
    
    var profilePicture : File {
        get {
            guard let fileId = self._profilePicture else {
                
             let workDir = Config.workingDirectory()
                let file = File.init(name: "defaultProfilePicture", path: "/img/profile/default-avatar.png", absolutePath: "\(workDir)public/img/profile/profile.png", user_id: self.id!, type: .image)
                return file
            }
            guard let file = try? File.find(fileId)! else {
                let workDir = Config.workingDirectory()
                let file = File.init(name: "defaultProfilePicture", path: "/img/profile/default-avatar.png", absolutePath: "\(workDir)public/img/profile/default-avatar.png", user_id: self.id!, type: .image)
                return file
            }
            
            return file
        }
    }
    init(username _username : String, email _email: String, password _password : Bytes, profilePicture _profilepic : Identifier? = nil, firstName _first : String, lastName _last : String) {
        username = _username
        email = _email
        password = _password
        firstName = _first
        lastName = _last
        _profilePicture = _profilepic
    }
    
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
