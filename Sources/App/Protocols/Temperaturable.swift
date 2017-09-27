//
//  Temperaturable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-27.
//

import Foundation
import Vapor
import FluentProvider

protocol Temperaturable : ObjectIdentifiable {
    func addCurrentTemperature()
}


extension Temperaturable {
    
    func addCurrentTemperature() {
        let temp = Temperature.init(object: self.objectType, objectId: self.objectIdentifier)
    }
}
