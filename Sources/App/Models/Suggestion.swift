//
//  Suggestion.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-27.
//

import Foundation
import Vapor
import FluentProvider

final class Suggestion : Model , Envyable, Attachable, Commentable{
    var objectIdentifier: Identifier {
        get {
            return self.id!
        }
    }
    var storage: Storage = Storage()
    
    func makeRow() throws -> Row {
        var row = Row()
        
        
        return row
    }
    
    init(row: Row) throws {
        
    }
    
    func getCreators() -> [Identifier] {
        var creators = [Identifier]()
        creators.append(self.id!)
        return creators
    }
}

extension Suggestion : Timestampable {}



