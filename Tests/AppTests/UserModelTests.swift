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
    
    func createUser() {
        var user = User.init()
        user.email = "test@test.com"
        user.username = "test1"
        user.password = try User.passwordHasher.make("password")
    }
    func testCreateUser() {
        var user = User.init()
        user.email = "test@test.com"
        user.username = "test1"
        user.password = try User.passwordHasher.make("password")
    }
}
