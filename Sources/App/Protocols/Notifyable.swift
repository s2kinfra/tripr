//
//  Notifyable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-22.
//

import Vapor
import FluentProvider

protocol Notifiable {
    func addNotification(from _from: Identifier, object _object: String, objectId _objectId : Identifier) throws
}

