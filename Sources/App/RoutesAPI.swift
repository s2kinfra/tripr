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

enum httpResponseStatusCode : Int {
    case success_ok = 200, success_created = 201, success_accepted = 202, success_no_content = 204,
    redirect_moved_perm = 301,
    client_error_bad_reequest = 400, client_error_unauthorized = 401, client_error_forbidden = 403, client_error_not_found = 404, client_error_to_many_requests = 429,
    server_error_internal_error = 500, server_error_not_implemented = 501, server_error_bad_gateway = 502, server_error_service_unavailble = 503
    
    var isErrorCode : Bool {
        if self.rawValue >= 300 {
            return true
        }else {
            return false
        }
    }
    
    var code_text : String {
        switch self {
        case .success_ok:
            return "OK"
        case .success_created:
            return "Created"
        case .success_accepted:
            return "Accepted"
        case .success_no_content:
            return "No Content"
        case .redirect_moved_perm:
            return "Moved Permanently"
        case .client_error_bad_reequest:
            return "Bad Request"
        case .client_error_unauthorized:
            return "Unauthorized"
        case .client_error_forbidden:
            return "Forbidden"
        case .client_error_not_found:
            return "Not Found"
        case .client_error_to_many_requests:
            return "To many requests"
        case .server_error_internal_error:
            return "Internal server error"
        case .server_error_not_implemented:
            return "Not implemented"
        case .server_error_bad_gateway:
            return "Bad gateway"
        case .server_error_service_unavailble:
            return "Service Unavailable"
        }
    }
    
}

struct APIErrorResponse {
    var status : httpResponseStatusCode
    var error : String
    
    init(status : httpResponseStatusCode, error : String) {
        self.status = status
        self.error = error
    }
    
     func sendError() throws -> ResponseRepresentable {
        return try self.makeJSON()
    }
}


extension APIErrorResponse: JSONConvertible {
    init(json: JSON) throws {
        self.init(status : try json.get("status"),
                  error : try json.get("error"))
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("status", status.rawValue)
        try json.set("error", error)
        return json
    }
    
}


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
        return try APIErrorResponse(status: .client_error_bad_reequest, error: "Something fukced up").sendError()
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
            print("user \(user.fullname) logged in")
            return try user.makeJSON()
        } catch let error {
            print(error.localizedDescription)
            return Response(status: .found, headers: ["Location": "/"])
        }
        
    }
}
