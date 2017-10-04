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
        
        do {
            let hashedPassword = try User.passwordHasher.make(password)
            let newUser = User.init(username: username.lowercased(), email: email.lowercased(), password: hashedPassword)
            try newUser.save()
            let user = try User.authenticate(Password.init(username: email.lowercased(), password: password))
            try request.auth.authenticate(user, persist: true)
        }catch {
            
            try flash?.addFlash(flashType: .error, message: "Unable to register")
            return Response(status: .found, headers: ["Location": "/"])
        }
        
        try flash?.addFlash(flashType: .success, message: "Welcome to Tripr!")
        return Response(status: .found, headers: ["Location": "/"])
    }
    
}
