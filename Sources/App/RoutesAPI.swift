//
//  RoutesAPI.swift
//  App
//
//  Created by Daniel Skevarp on 2018-01-03.
//

import Foundation
import Vapor
import LeafProvider
import AuthProvider
import MySQL

final class RoutesApi: RouteCollection {
    
    let drop : Droplet
    
    
    init(drop : Droplet) {
        self.drop = drop
    }
    
    func build(_ builder: RouteBuilder) throws {
        
        
        // root
        builder.group("api") { api in
            api.group("v1") { v1 in
                
                v1.group("user") { user in
                    user.post("login", handler: loginUser)
                }
                
                v1.group("error") { error in
                    error.get("", handler: sendError)
                    error.post("", handler: sendError)
                }
            }
        }
        
    }
    
    func sendError(request: Request) throws -> ResponseRepresentable {
        var body = JSON()
        try body.set("status", 401)
        try body.set("error", "Fuck something went wrong")
        return try Response(status: .badRequest, json: body)
    }
    
    func loginUser(request: Request) throws -> ResponseRepresentable {
        guard let username = request.data["email"]?.string,
            let password = request.data["password"]?.string else {
                
                return Response(status: .found, headers: ["Location": "/"])
                //return try self.viewFactory.renderView(path: "index", request: request)
        }
        
        let passwordCredentials = Password(username: username.lowercased(), password: password)
        do {
            let user = try User.authenticate(passwordCredentials)
            try request.auth.authenticate(user, persist: true)
            return try user.makeJSON()
        } catch let error {
            print(error.localizedDescription)
            return Response(status: .found, headers: ["Location": "/"])
        }
        
    }
}
