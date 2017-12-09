//
//  PlaceController.swift
//  App
//
//  Created by Daniel Skevarp on 2017-11-14.
//

import Foundation
import Vapor
import HTTP
import AuthProvider
import BCrypt
import MapKit
import CoreLocation

class PlaceController {
    
    let viewFactory : LeafViewFactory
    
    init(viewFactory : LeafViewFactory){
        self.viewFactory = viewFactory
    }
    func addRoutes(drop: Droplet){
        let passmw = PasswordAuthenticationMiddleware(User.self)
        
        let secureArea = drop.grouped(passmw)
        secureArea.group("place") {
            place in
            place.get("new", handler: createPlaceView)
            place.post("create", handler: createPlace)
            place.get("searchPOI" , handler: searchPOI)
            place.group(Place.parameter){ splace in
                splace.get("", handler: viewPlace)
                splace.post("addPOI", handler: addPOI)
                splace.post("addComment", handler: addComment)
                splace.post("addPhoto", handler: addPhoto)
            }
            
        }
    }
    
    func searchPOI(request: Request) throws -> ResponseRepresentable {
        
        guard let lat = request.data["lat"]?.string else {
            throw Abort(.badRequest, reason: "No lat?! 😱")
        }
        guard let lng = request.data["lng"]?.string else {
            throw Abort(.badRequest, reason: "No lng?! 😱")
        }
        guard let strng = request.data["strng"]?.string else {
            throw Abort(.badRequest, reason: "No strng?! 😱")
        }
        
        return "\(lat) \(lng) \(strng)"
        
    }
    func addPhoto(request: Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        
        guard let place = try? request.parameters.next(Place.self) else {
            try flash?.addFlash(flashType: .error, message: "Place couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        let user = try request.user()
        
        let file = try FileHandler.uploadFile(user: user, request: request)
        
        guard let comment = request.formData?["file_comment"]?.string else {
            throw Abort(.badRequest, reason: "No comment?! 😱")
        }
        
        _ = try place.addAttachment(file: file, createFeed: true)
        _ = try file.addComment(by: user.id!, commment: comment)
        
        place._photo = file.id!
        try place.save()
        
        if let coord = FileHandler.getCoordinatesForFile(file: file) {
            try POI.downloadPlacesFor(longitude: coord.longitude, latitude: coord.latitude, createdBy: user.id!)
        }
        
        try flash?.addFlash(flashType: .success, message: "Photo added to the place!")
        return try ViewCache.instance.back(request: request)
    }
    
    func addComment(request: Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        
        guard let trip = try? request.parameters.next(Trip.self) else {
            try flash?.addFlash(flashType: .error, message: "Trip couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        guard let comment = request.formData?["comment"]?.string else {
            throw Abort(.badRequest, reason: "No comment?! 😱")
        }
        
        let user = try request.user()
        try trip.addComment(by: user.id!, commment: comment, createFeed : true)
        
        try flash?.addFlash(flashType: .success, message: "Comment added to the trip!")
        return try ViewCache.instance.back(request: request)
    }
    
    func addPOI(request: Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        
        guard let place = try? request.parameters.next(Place.self) else {
            try flash?.addFlash(flashType: .error, message: "Place couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        guard let placeId = request.data["placeId"]?.string else {
            throw Abort(.badRequest, reason: "no place id! 😱")
        }
        
        guard let poi = try? POI.getPOIFrom(placeId: placeId) else {
            place.POI_id = nil
            try place.save()
            try flash?.addFlash(flashType: .success, message: "POI added to the place!")
            return try ViewCache.instance.back(request: request)
        }
        
        place.POI_id = poi.id
        try place.save()
        try flash?.addFlash(flashType: .success, message: "POI added to the place!")
        return try ViewCache.instance.back(request: request)
    }
    
    func viewPlace(request: Request) throws -> ResponseRepresentable {
        //        TODO validate if i should be able to see this trip?
        
        //        let file = try File.find(3)
        //        let place = try Place.init(fromFile: file!)
        let flash = FlashMessage.init(request: request)
        
        guard let place = try? request.parameters.next(Place.self) else {
            try flash?.addFlash(flashType: .error, message: "Place couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        let pois = try POI.getNearByPlaces(place: place, distance: 200)
        
        return try viewFactory.renderView(path: "Place/place_details", request: request, parameters:  ["place" : try place.makeJSON(),
                                                                                                       "pois" : try pois.makeJSON()
            ])
    }
    
    func createPlace(request: Request) throws -> ResponseRepresentable {
        let user = try request.user()
        
        guard let name = request.formData?["name"]?.string else {
            throw Abort(.badRequest, reason: "No name! 😱")
        }
        guard let description = request.formData?["description"]?.string else {
            throw Abort(.badRequest, reason: "No description! 😱")
        }
        guard let startdate = request.formData?["startdate"]?.string else {
            throw Abort(.badRequest, reason: "No description! 😱")
        }
        guard let enddate = request.formData?["enddate"]?.string else {
            throw Abort(.badRequest, reason: "No description! 😱")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let sdate = dateFormatter.date(from: startdate)?.timeIntervalSince1970
        let edate = dateFormatter.date(from: enddate)?.timeIntervalSince1970
        
        
        let trip = try Trip.init(name: name, tripStart: sdate!, tripEnd: edate!, createdBy: user.id!,description : description)
        
        try trip.save()
        try trip.attendees.add(user)
        try trip.save()
        
        let flash = FlashMessage.init(request: request)
        try flash?.addFlash(flashType: .success, message: "Trip created!")
        return try ViewCache.instance.back(request: request)
    }
    
    func createPlaceView(request: Request) throws -> ResponseRepresentable {
        return try viewFactory.renderView(path: "Trip/trip_create", request: request)
    }
    
}
