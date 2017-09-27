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
}

extension ObjectIdentifiable {
    var objectType : String {
        get {
            return String(describing: self)
        }
    }
}
