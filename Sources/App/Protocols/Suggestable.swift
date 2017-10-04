//
//  Suggestable.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-27.
//

import Foundation
import Vapor
import FluentProvider

protocol Suggestable : ObjectIdentifiable{
    var suggestions : [Suggestion] {get}
    func addSuggestion(by: Identifier) throws
    func removeSuggestion(suggestion : Suggestion) throws
}

extension Suggestable {
    
    var suggestions : [Suggestion] {
        get {
            guard let suggestions = try? Suggestion.makeQuery().and( { andGroup in
                try andGroup.filter("suggestedObject", .equals, objectType)
                try andGroup.filter("suggestedObjectId", .equals, objectIdentifier)
            }).all() else {
                return [Suggestion]()
            }
            return suggestions
        }
    }
    func addSuggestion(by: Identifier) throws{
        let suggestion = Suggestion.init(createdBy: by , suggestedObject:objectType , suggestedObjectId: objectIdentifier)
        try suggestion.save()
    }
    
    func removeSuggestion(suggestion : Suggestion) throws{
        try suggestion.delete()
    }
}
