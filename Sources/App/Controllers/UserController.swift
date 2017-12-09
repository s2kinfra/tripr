//
//  UserController.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-27.
//

import Foundation
import Vapor
import HTTP
import AuthProvider
import BCrypt

class UserController {
    
    let viewFactory : LeafViewFactory
    
    init(viewFactory : LeafViewFactory){
        self.viewFactory = viewFactory
    }
    func addRoutes(drop: Droplet){
        let passmw = PasswordAuthenticationMiddleware(User.self)
        
        let secureArea = drop.grouped(passmw)
        secureArea.group(User.parameter) {
            user in
            user.get("", handler: home)
            user.get("follow", handler: followUser)
            user.get("unfollow", handler: stopFollowUser)
            user.get("acceptfollow", handler: acceptFollow)
            user.get("declinefollow", handler: declineFollow)
            user.get("edit_profile", handler: editProfileView)
            user.post("profileCover", handler: setProfileCover)
            user.post("profilePicture", handler: setProfilePicture)
            user.group("notifications") {
                notif in
                notif.get("", handler: viewNotifications)
            }
            let profile = user.grouped("profile")
            profile.post("update", handler: updateProfileInformation)            
        }
        
        secureArea.group("feed",Feed.parameter) {
            feed in
            feed.post("comment", handler: feedAddComment)
            feed.get("envy", handler: feedAddEnvy)
            
        }
        
        drop.group("user") {user in
            user.post("login", handler: login)
            user.post("register", handler: register)
            let session = user.grouped(passmw)
            session.get("logout", handler: logout)
            
            let profile = user.grouped(User.parameter)
            profile.get("profile", handler: profileView)
        }
        
        //drop.middleware.append(tokenMiddleware)
    }
    
    func viewNotifications(request: Request) throws -> ResponseRepresentable {
        
        guard let notif_id = request.data["notif"]?.int else {
            return try viewFactory.renderView(path: "Notifications/notifications", request: request)
        }
        
        guard let notif = try Notification.find(notif_id) else {
            throw Abort(.badRequest, reason: "No notification found for id \(notif_id)! 😱")
        }
        notif.read = true
        try notif.save()
        
        return try viewFactory.renderView(path: "Notifications/notifications", request: request, parameters: ["selected_notif" : notif.makeJSON()])
    }
    
    func feedAddEnvy(request: Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        guard let feed = try? request.parameters.next(Feed.self) else {
            try flash?.addFlash(flashType: .error, message: "Feed couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        let user = try request.user()
        
        if try feed.isObjectEnviedBy(user: user.id!){
            try flash?.addFlash(flashType: .error, message: "You have already envied this feed")
            return try ViewCache.instance.back(request: request)
        }else {
            try feed.addEnvyBy(user: user)
            return try ViewCache.instance.back(request: request)
        }
    }
    
    func feedAddComment(request: Request ) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        guard let feed = try? request.parameters.next(Feed.self) else {
            return Response(status: .found, headers: ["Location": "/"])
        }
        guard let comment = request.formData!["comment"]?.string! else {
            try flash?.addFlash(flashType: .error, message: "Comment couldnt be added")
            return try ViewCache.instance.back(request: request)
        }
        
        if comment.count < 1 {
            try flash?.addFlash(flashType: .error, message: "Comment has to be atleast 1 character long")
            return try ViewCache.instance.back(request: request)
        }
        
        let user = try request.user()
        
        let _ = try feed.addComment(by: user.id!, commment: comment)
        return try ViewCache.instance.back(request: request)
    }
    
    func setProfilePicture(request : Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        guard let user = try? request.parameters.next(User.self) else {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        let file = try FileHandler.uploadFile(user: user, request: request)
        
        user._profilePicture = file.id
        try user.save()
        try flash?.addFlash(flashType: .success, message: "Profile Picture updated!")
        return try ViewCache.instance.back(request: request)
    }
    func setProfileCover(request : Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        guard let user = try? request.parameters.next(User.self) else {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        let file = try FileHandler.uploadFile(user: user, request: request)
        
        user._profileCover = file.id
        try user.save()
        try flash?.addFlash(flashType: .success, message: "Profile Cover updated!")
        return try ViewCache.instance.back(request: request)
    }
    
    func updateProfileInformation(request: Request) throws -> ResponseRepresentable {
        
        let user = try request.user()
        
        guard let firstname = request.formData?["firstname"]?.string else {
            throw Abort(.badRequest, reason: "No file! 😱")
        }
        guard let lastname = request.formData?["lastname"]?.string else {
            throw Abort(.badRequest, reason: "No file! 😱")
        }
        
        user.firstName = firstname
        user.lastName = lastname
        try user.save()
        let flash = FlashMessage.init(request: request)
        try flash?.addFlash(flashType: .info, message: "User information updated.")
        return try ViewCache.instance.back(request: request)
    }
    func editProfileView(request : Request) throws -> ResponseRepresentable {
        return try viewFactory.renderView(path: "User/Profile/profile_edit", request: request)
    }
    
    func declineFollow(request: Request) throws -> ResponseRepresentable {
        guard let profile = try? request.parameters.next(User.self) else {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        let user = try request.user()
        if (profile.id == user.id) {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        let flash = FlashMessage.init(request: request)
        
        do {
            try user.declineFollow(follower: profile.id!)
        } catch {
            try flash?.addFlash(flashType: .error, message: "Faild to decline follow request")
            return try ViewCache.instance.back(request: request)
        }
        try flash?.addFlash(flashType: .info, message: "\(profile.firstName) \(profile.lastName) (@\(profile.username)) follow request was declined")
        return try ViewCache.instance.back(request: request)
    }
    
    func acceptFollow(request: Request) throws -> ResponseRepresentable {
        guard let profile = try? request.parameters.next(User.self) else {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        let user = try request.user()
        if (profile.id == user.id) {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        let flash = FlashMessage.init(request: request)
        
        do {
            try user.acceptFollow(follower: profile.id!)
        } catch {
            try flash?.addFlash(flashType: .error, message: "Faild to accept follow request")
            return try ViewCache.instance.back(request: request)
        }
        
        let notif = Notification.init(relatedObject: profile.objectType, relatedObjectId: profile.objectIdentifier, receiver: profile.id!, sender: user.id!)
        notif.comment = "\(user.fullname) accepted your follow request"
        
        try Feed.createNewFeed(createdBy: profile.id!, feedText: "\(profile.fullname)) is now following \(user.fullname)", feedObject: user.objectType, feedObjectId: user.id!, feedType: .followAccepted, targetId: profile.id!)
        
        try flash?.addFlash(flashType: .success, message: "\(profile.firstName) \(profile.lastName) (@\(profile.username)) is now following you")
        return try ViewCache.instance.back(request: request)
    }
    
    func stopFollowUser(request: Request) throws -> ResponseRepresentable {
        guard let profile = try? request.parameters.next(User.self) else {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        let user = try request.user()
        if (profile.id == user.id) {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        
        let flash = FlashMessage.init(request: request)
        
        do {
            try profile.stopFollowing(by: user.id!)
        } catch {
            try flash?.addFlash(flashType: .error, message: "Faild to add follow request")
            return try ViewCache.instance.back(request: request)
        }
        try flash?.addFlash(flashType: .success, message: "You have unfollowed \(profile.username)")
        return try ViewCache.instance.back(request: request)
    }
    
    func followUser(request: Request) throws -> ResponseRepresentable {
        guard let profile = try? request.parameters.next(User.self) else {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        let user = try request.user()
        if (profile.id == user.id) {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        
        let flash = FlashMessage.init(request: request)
        
        do {
            try profile.startFollowing(by: user.id!)
        } catch {
            try flash?.addFlash(flashType: .error, message: "Faild to add follow request")
            return try ViewCache.instance.back(request: request)
        }
        try flash?.addFlash(flashType: .success, message: "Follow request sent")
        let notif = Notification.init(relatedObject: user.objectType, relatedObjectId: user.objectIdentifier, receiver: profile.id!, sender: user.id!)
        notif.comment = "\(user.fullname) Requested to follow you"
        try notif.save()
         try Feed.createNewFeed(createdBy: user.id!, feedText: "\(user.fullname) is requesting to follow \(profile.fullname)", feedObject: user.objectType, feedObjectId: profile.id!, feedType: .followRequest, targetId: profile.id!)
        return try ViewCache.instance.back(request: request)
    }
    
    func home(request: Request) throws -> ResponseRepresentable {
        guard let profile = try? request.parameters.next(User.self) else {
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        
        return try viewFactory.renderView(path: "User/Profile/profile", request: request, parameters:  ["profile" : try profile.makeJSON(),
                                                                                                        "trips" : try Trip.getTripsFor(user: profile.id!).makeJSON()
                                                                                                        ])
        //        "timeline" : try profile.getFeedObjects(limit: 20).makeJSON()
    }
    
    func profileView(request: Request) throws -> ResponseRepresentable {
        //        guard let user = try? request.parameters.next(User.self) else {
        //            return Response(status: .found, headers: ["Location": "/"])
        //        }
        //
        //
        //        return try viewFactory.renderView(path: "profile", request: request, parameters:  ["profile" : user.makeJSON(),
        //                                                                                           "followers" : user.friendOf.makeJSON(),
        //                                                                                           "following": user.myFriends.makeJSON()
        //            ])
        return "strng"
    }
    
    func logout( request : Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        try request.auth.unauthenticate()
        try flash?.addFlash(flashType: .success, message: "You are now logged out")
        return Response(status: .found, headers: ["Location": "/"])
    }
    
    func login(request : Request) throws -> ResponseRepresentable {
        
        let flash = FlashMessage.init(request: request)
        
        guard let username = request.data["email"]?.string,
            let password = request.data["password"]?.string else {
                try flash?.addFlash(flashType: .error, message: "Email and Password is mandatory")
                return Response(status: .found, headers: ["Location": "/"])
                //return try self.viewFactory.renderView(path: "index", request: request)
        }
        
        let passwordCredentials = Password(username: username.lowercased(), password: password)
        do {
            let user = try User.authenticate(passwordCredentials)
            try request.auth.authenticate(user, persist: true)
            try flash?.addFlash(flashType: .success, message: "Logged in as \(user.username)")
        } catch {
            try flash?.addFlash(flashType: .error, message: "Invalid email and/or password")
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        
        return Response(status: .found, headers: ["Location": "/"])
        
        
    }
    
    
    func register(request : Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        
        // check that email and password are supplied
        guard let email = request.data["email"]?.string else {
            try flash?.addFlash(flashType: .error, message: "Email is mandatory")
            return Response(status: .found, headers: ["Location": "/"])
        }
        guard let username = request.data["username"]?.string else {
            try flash?.addFlash(flashType: .error, message: "Username is mandatory")
            return Response(status: .found, headers: ["Location": "/"])
        }
        guard let password = request.data["password"]?.string else {
            try flash?.addFlash(flashType: .error, message: "Password is mandatory")
            return Response(status: .found, headers: ["Location": "/"])
        }
        guard let firstName = request.data["firstName"]?.string else {
            try flash?.addFlash(flashType: .error, message: "Firstname is mandatory")
            return Response(status: .found, headers: ["Location": "/"])
        }
        guard let lastName = request.data["lastName"]?.string else {
            try flash?.addFlash(flashType: .error, message: "Lastname is mandatory")
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        do {
            let hashedPassword = try User.passwordHasher.make(password)
            let newUser = User.init(username: username.lowercased(), email: email.lowercased(), password: hashedPassword, firstName : firstName, lastName : lastName)
            try newUser.save()
            let user = try User.authenticate(Password.init(username: email.lowercased(), password: password))
            try request.auth.authenticate(user, persist: true)
        }catch let error{
            
            try flash?.addFlash(flashType: .error, message: "Unable to register: \(error.localizedDescription)")
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        try flash?.addFlash(flashType: .success, message: "Welcome to Tripr!")
        return Response(status: .found, headers: ["Location": "/"])
    }
    
}
