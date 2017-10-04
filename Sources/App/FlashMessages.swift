////
////  FlashMessages.swift
////  tripr
////
////  Created by Daniel Skevarp on 2017-05-30.
////
////
//
import Foundation
import Vapor
import Sessions

enum FlashType : String{
    case success ,error, info, warning
}

final class FlashMessage{
    
    var flashes = [String:[String]]()
    var session : Session
    
    init?(request : Request) {
        do {
            self.session = try request.assertSession()
            if let _flashes = try? session.data.get("_flashes") as [String: [String]]{
                self.flashes = _flashes
            }
        }catch {
            return nil
        }
    }
    
    init(flashes _flashes : [String: [String]]) {
        self.session = Session.init(identifier: "sessions:session")
        self.flashes = _flashes
    }
    
    func addFlash(flashType : FlashType, message _message : String) throws
    {
        
        guard let _ = flashes[flashType.rawValue] else {
            flashes[flashType.rawValue] = [_message]
            try session.data.set("_flashes", flashes)
            return
        }
        
        flashes[flashType.rawValue]!.append(_message)
        try session.data.set("_flashes", flashes)
    }
    
    func getFlashesFor(flashtype _ft : FlashType) throws -> [String]
    {
        guard let _flashes = flashes[_ft.rawValue] else {
            return []
        }
        return _flashes
    }
    
//    func getFlashesFor(domain _domain : String) throws -> Node
//    {
//        
//        guard let _ = flashes[_domain] else {
//            return []
//        }
//        
//        return try flashes[_domain]!.makeNode()
//    }
    
    func clearFlashes() {
        flashes.removeAll()
        session.data["_flashes"] = nil
    }
    
    func hasFlashesIn(flashtype _ft : FlashType) -> Bool
    {
        
        guard let _flashes = flashes[_ft.rawValue] else {
            return false
        }
        if (_flashes.count) > 0
        {
            return true
        }
        return false
    }
    
    func hasFlashes() -> Bool {
        if flashes.count > 0 {
            return true
        }
        return false
    }
}

extension FlashMessage: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            flashes: json.get("flashes")
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("flashes", flashes)
        
        return json
    }
}

