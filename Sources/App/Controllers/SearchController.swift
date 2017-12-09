//
//  SearchController.swift
//  App
//
//  Created by Daniel Skevarp on 2017-10-30.
//


import Foundation
import Vapor
import HTTP
import AuthProvider
import BCrypt

struct searchResult {
    var slug : String
    var name : String
    var icon : String
    var url : String
    var objType : String
}

extension searchResult : JSONConvertible {
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("slug",slug)
        try json.set("name",name)
        try json.set("icon",icon)
        try json.set("url",url)
        try json.set("objType",objType)
        return json
    }
    
    init(json: JSON) throws {
        self.init(slug: try json.get("slug"),
                  name: try json.get("name"),
                  icon: try json.get("icon"),
                  url: try json.get("url"),
                  objType: try json.get("objType"))
    }
    
    
}
class SearchController {
    
    let viewFactory : LeafViewFactory
    
    init(viewFactory : LeafViewFactory){
        self.viewFactory = viewFactory
    }
    
    func addRoutes(drop: Droplet){
        let passmw = PasswordAuthenticationMiddleware(User.self)
        
        let secureArea = drop.grouped(passmw)
        secureArea.group("search") {
            search in
            search.group("user"){ user in
                user.get("", String.parameter , handler: searchUser)
            }
            search.group("trip"){ trip in
                trip.get("",String.parameter, handler: searchTrip)
            }
            search.group("all"){ all in
                all.get("", String.parameter, handler: searchAll)
            }
            search.group("country"){ country in
                country.get("", String.parameter, handler: searchCountry)
            }
            search.group("city"){ city in
                city.get("", handler: searchCity)
            }
            
        }
    }
    
    func searchAll(request: Request) throws -> ResponseRepresentable {
        let searchString = try request.parameters.next(String.self)
        
        if searchString.count < 3 {
            return ""
        }
        
        let found = try User.makeQuery().or{ orGroup in
            try orGroup.filter("username", .contains, searchString)
            try orGroup.filter("firstName", .contains, searchString)
            try orGroup.filter("lastName", .contains, searchString)
            }.distinct().all()
        
        let found2 = try Trip.makeQuery().or{ orGroup in
            try orGroup.filter("name", .contains, searchString)
            try orGroup.filter("tripDescription", .contains, searchString)
            }.distinct().all()
        
        var json = JSON()
        
        var result = [searchResult]()
        
        for user in found {
            let res = searchResult.init(slug: user.username,
                                        name: user.fullname,
                                        icon: user.profilePicture.path,
                                        url: user.getURL(),
                                        objType: "users")
            result.append(res)
        }
        
        for trip in found2{
            let res = searchResult.init(slug: trip.tripDescription,
                                        name: trip.name,
                                        icon: trip.cover.path,
                                        url: trip.getURL(),
                                        objType: "trips")
            result.append(res)
        }
        try json.set("data", result)
        return json
    }
    
    func searchCountry(request: Request) throws -> ResponseRepresentable {
        let searchString = try request.parameters.next(String.self)
        
        let test = "SELECT * FROM `countries` WHERE `name` LIKE '%\(searchString)%' "
        let found = try POI.database?.raw(test)
        
        guard let data = found?.wrapped.array else {
            return ""
        }
        
        var json = JSON()
        
        try json.set("countries", data)
        return json
    }
    
    func searchCity(request : Request) throws -> ResponseRepresentable {
        
        let searchString = request.data["search"]?.string
        let countryCode = request.data["country_id"]?.int
        
        let found = try City.makeQuery().and{ andGroup in
            try andGroup.filter("country_id", .equals, countryCode)
            try andGroup.filter("name", .contains, searchString)
        }.distinct().all()
        
        return try found.makeJSON()
    }
    
    func searchTrip(request: Request) throws -> ResponseRepresentable {
        let searchString = try request.parameters.next(String.self)
        
        if searchString.count < 3 {
            return ""
        }
        
        let found = try Trip.makeQuery().or{ orGroup in
            try orGroup.filter("name", .contains, searchString)
            try orGroup.filter("tripDescription", .contains, searchString)
            }.distinct().all()
        
        //        var uniqFound = [User]()
        //        for (_ , element) in found.enumerated() {
        //            if !uniqFound.contains(where: { user in
        //                user.id == element.id
        //            }){
        //                uniqFound.append(element)
        //            }
        //        }
        
        
        return try found.makeJSON()
    }
    
    func searchUser(request: Request) throws -> ResponseRepresentable {
        let searchString = try request.parameters.next(String.self)
     
        if searchString.count < 3 {
            return ""
        }
        
        let found = try User.makeQuery().or{ orGroup in
            try orGroup.filter("username", .contains, searchString)
            try orGroup.filter("firstName", .contains, searchString)
            try orGroup.filter("lastName", .contains, searchString)
        }.distinct().all()
        
//        var uniqFound = [User]()
//        for (_ , element) in found.enumerated() {
//            if !uniqFound.contains(where: { user in
//                user.id == element.id
//            }){
//                uniqFound.append(element)
//            }
//        }
        
        
        return try found.makeJSON()

    }
    
    
    
}

