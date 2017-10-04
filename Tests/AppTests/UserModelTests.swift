//
//  UserModelTests.swift
//  AppTests
//
//  Created by Daniel Skevarp on 2017-09-26.
//

import Foundation
import XCTest
import Testing
import HTTP
import Sockets
@testable import Vapor
@testable import App


class UserTests : TestCase{
    
    func createUser() throws -> User{
        let user = User.init()
        user.email = "test@test.com"
        user.username = "test1"
        user.password = try User.passwordHasher.make("password")
        return user
    }
    func testCreateUser() throws {
        let user = User.init()
        user.email = "test@test.com"
        user.username = "test1"
        user.password = try User.passwordHasher.make("password")
    }
    
    func testFollow() throws {
        
        let user1 = try createUser()
        let user2 = try createUser()
        try user1.startFollowing(by: user2.id!)
        try user2.acceptFollow(follower: user1.id!)
    }
}
