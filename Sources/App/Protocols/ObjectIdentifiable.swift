//
//  ObjectIdentifiable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-26.
//

import Foundation
protocol ObjectIdentifiable {
    var objectType : String { get }
    var objectIdentifier : Identifier { get }
    static var objectType : String { get }
}

extension ObjectIdentifiable {
    static var objectType : String {
        get {
            return "App.\(String(describing: self))"
        }
    }
    var objectType : String {
        get {
            return String(describing: self)
        }
    }
}
