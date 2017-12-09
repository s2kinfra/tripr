//
//  LeafViewFactory.swift
//  tripr
//
//  Created by Daniel Skevarp on 2017-05-02.
//
//

import Foundation
import Vapor
import HTTP
import URI
import FluentProvider

struct LeafViewFactory {
    
    let viewRenderer: ViewRenderer
   
    public func renderView(path _path : String, request _request: Request, parameters _parameters : [String: NodeRepresentable] = [:]) throws -> View
    {
        var viewParameters = [String: NodeRepresentable]()
        viewParameters = _parameters
                
        if _request.auth.isAuthenticated(User.self) {
            let user = try _request.user()
            viewParameters["user"] = try user.makeJSON()
            ViewCache.addCache(path: _request.uri.path, uniqueId: user.username)
        }
        
        if let flashes = FlashMessage.init(request: _request) {
            if flashes.hasFlashes() {
                
                print(try flashes.makeJSON())
                viewParameters["flashes"] = try flashes.makeJSON()
                flashes.clearFlashes()
            }
        }

        return try viewRenderer.make(_path ,viewParameters)
    }
    
    public func makeModelArrayToRow(array : [Model]) throws -> [NodeRepresentable]{
        var newArray = [NodeRepresentable]()
        for item in array.enumerated() {
            let rowAble = item.element
            newArray.append(try rowAble.makeRow())
        }
        
        return newArray
    }
}

class ViewCache {
    
    
    var path : [[String : String]] = [[String:String]]()
    
    // Can't init is singleton
    private init() {}
    
    
    public static let instance: ViewCache = ViewCache()
    
    public static func addCache(path _path : String, uniqueId : String)
    {
        let cache = ViewCache.instance
        let path = [uniqueId : _path]
        cache.cleanPaths(uniqueID: uniqueId)
        cache.path.append(path)
    }
    
    public func back(request: Request) throws -> ResponseRepresentable {
        if let account = try? request.user() {
            for (index , _) in self.path.enumerated()
            {
                if let path = self.path[index][account.username] {
                    return Response(status: .found, headers: ["Location": path])
                }
            }
        }
       return Response(redirect: "/")
    }
    
    public func cleanPaths(uniqueID : String) {
        for (index , item) in self.path.enumerated()
        {
            if item.first?.key == uniqueID {
                self.path.remove(at: index)
            }
        }
    }

}
