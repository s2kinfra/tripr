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
}

