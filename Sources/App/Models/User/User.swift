//
//  User.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-20.
//

import Vapor
import FluentProvider

enum userStatuses : Int {
    case level1,level2,level3,level4,level5
    
    var asText : String {
        switch self {
        case .level1:
            return "Dreamer"
        case .level2:
            return "Traveler"
        case .level3:
            return "Experienced"
        case .level4:
            return "World as home"
        case .level5:
            return "Globetrotter"
            
        }
    }
}
final class User {
    var storage = Storage()
    
    var username: String = ""
    var email : String = ""
    var firstName : String = ""
    var lastName : String = ""
    var password : Bytes
    var status : userStatuses = .level1
    var _profilePicture : Identifier?
    
    var unreadNotifications : [Notification] {
        get {
            do {
                let notif = try Notification.makeQuery().filter("receiver", .equals, self.objectIdentifier).filter("read", .equals, false).all()
                return notif
            }catch{
                return [Notification]()
            }
        }
    }
    var notifications : [Notification] {
        get {
            do {
                let notif = try Notification.makeQuery().filter("receiver", .equals, self.objectIdentifier).sort("timestamp", .descending).all()
                return notif
            }catch{
                return [Notification]()
            }
        }
    }
    var fullname : String {
        get {
            if (firstName.count < 1){
                return username
            }
            
            return "\(self.firstName) \(self.lastName)"
        }
        
    }
    
    var _profileCover : Identifier?
    
    var profileCover : File {
        get {
            guard let fileId = self._profileCover else {
                
                let workDir = Config.workingDirectory()
                let file = File.init(name: "defaultProfileCover", path: "/img/login_back.jpg", absolutePath: "\(workDir)public/img/login_back.jpg", user_id: self.id!, type: .image)
                return file
            }
            guard let file = try? File.find(fileId)! else {
                let workDir = Config.workingDirectory()
                let file = File.init(name: "defaultProfileCover", path: "/img/login_back.jpg", absolutePath: "\(workDir)public/img/login_back.jpg", user_id: self.id!, type: .image)
                return file
            }
            
            return file
        }
    }
    
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
    
    func getURL()->String{
        return "/\(self.username)"
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
