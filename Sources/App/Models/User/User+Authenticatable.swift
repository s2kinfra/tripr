//
//  User+Authenticatable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-21.
//

import Vapor
import AuthProvider
import BCrypt

extension User: PasswordAuthenticatable {
    
    public static let passwordVerifier: PasswordVerifier? = User.passwordHasher
    public var hashedPassword: String? {
        return password.makeString()
    }
    public static let passwordHasher = BCryptHasher(cost: 10)
    
    public static func authenticate(_ creds: Password) throws -> User {
        let user: User
        
        if let verifier = passwordVerifier {
            guard let match = try User
                .makeQuery()
                .or( { orGroup in
                    try orGroup.filter(usernameKey, creds.username)
                    try orGroup.filter("username", creds.username)
                })
                .first()
                else {
                    throw AuthenticationError.invalidCredentials
            }
            
            guard let hash = match.hashedPassword else {
                throw AuthenticationError.invalidCredentials
            }
            
            guard try verifier.verify(
                password: creds.password.makeBytes(),
                matches: hash.makeBytes()
                ) else {
                    throw AuthenticationError.invalidCredentials
            }
            
            user = match
        } else {
            guard let match = try User
                .makeQuery()
                .or({orGroup in
                    try orGroup.filter(usernameKey, creds.username)
                    try orGroup.filter("username", creds.username)
                })
                .filter(passwordKey, creds.password)
                .first()
                else {
                    throw AuthenticationError.invalidCredentials
            }
            
            user = match
        }
        
        return user
    }
    
}

