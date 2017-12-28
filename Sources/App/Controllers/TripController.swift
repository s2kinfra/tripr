//
//  TripController.swift
//  App
//
//  Created by Daniel Skevarp on 2017-10-19.
//

import Foundation
import Vapor
import HTTP
import AuthProvider
import BCrypt
import MapKit
import CoreLocation

class TripController {
    
    let viewFactory : LeafViewFactory
    
    init(viewFactory : LeafViewFactory){
        self.viewFactory = viewFactory
    }
    func addRoutes(drop: Droplet){
        let passmw = PasswordAuthenticationMiddleware(User.self)
        
        let secureArea = drop.grouped(passmw)
        secureArea.group("trip") {
            trip in
            trip.get("new", handler: createTripView)
            trip.post("create", handler: createTrip)
            trip.get("searchPOI" , handler: searchPOI)
            trip.group(Trip.parameter){ strip in
                strip.get("", handler: viewTrip)
                strip.post("addAttendant", handler: addAttendant)
                strip.post("addComment", handler: addComment)
                strip.post("addPhoto", handler: addPhoto)
                strip.get("follow", handler: followTrip)
            }
            
        }
    }
    
    func followTrip(request: Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        
        guard let trip = try? request.parameters.next(Trip.self) else {
            try flash?.addFlash(flashType: .error, message: "Trip couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        
        let user = try request.user()
        
        try trip.startFollowing(by: user.id!)
        try trip.acceptFollow(follower: user.id!)
        
        try Feed.createNewFeed(createdBy: user.id!, feedText: "\(user.fullname) is now following \(trip.name)", feedObject: trip.objectType, feedObjectId: trip.id!, feedType: .tripFollowed, targetId: trip.id!)
        
        for follower in trip.followers.enumerated() {
            if (try follower.element.getFollowerUser().id! != user.id!){
                let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, receiver: try follower.element.getFollowerUser().id!, sender: user.id!)
                notification.comment = "<a href=\"\(user.getURL())\">\(user.fullname)</a> is now following trip <a href=\"\(trip.getURL())\">\(trip.name)</a>"
                try notification.save()
            }
        }
        
        for attendee in try trip.attendees.all().enumerated() {
            if (attendee.element.id! != user.id!){
                let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, receiver: attendee.element.id!, sender: user.id!)
                notification.comment = "<a href=\"\(user.getURL())\">\(user.fullname)</a> is now following trip <a href=\"\(trip.getURL())\">\(trip.name)</a>"
                try notification.save()
            }
        }
        
        try flash?.addFlash(flashType: .success, message: "You are now following this trip!")
        return try ViewCache.instance.back(request: request)
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
        
        guard let trip = try? request.parameters.next(Trip.self) else {
            try flash?.addFlash(flashType: .error, message: "Trip couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        
        let user = try request.user()
        
        let file = try FileHandler.uploadFile(user: user, request: request)
        
        guard let comment = request.formData?["file_comment"]?.string else {
            throw Abort(.badRequest, reason: "No comment?! 😱")
        }
        
        if let _ = request.formData?["createPlace"]?.bool  {
            guard let lng = request.formData?["longitude"]?.double else {
                throw Abort(.badRequest, reason: "No comment?! 😱")
            }
            guard let lat = request.formData?["latitude"]?.double else {
                throw Abort(.badRequest, reason: "No comment?! 😱")
            }
            guard let placename = request.formData?["placename"]?.string else {
                throw Abort(.badRequest, reason: "No comment?! 😱")
            }
            
            let place = Place.init(longitude: lng, latitude: lat, name: placename, createdBy: user.id!, poi_id: nil)
            place.relatedObject = trip.objectType
            place.relatedObjectId = trip.objectIdentifier
            place._photo = file.id!
            try place.save()
        }
        
        
        _ = try file.addComment(by: user.id!, commment: comment)
        _ = try trip.addAttachment(file: file, createFeed: true)
        
        if let coord = FileHandler.getCoordinatesForFile(file: file) {
            try POI.downloadPlacesFor(longitude: coord.longitude, latitude: coord.latitude, createdBy: user.id!)
        }
        
        let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, sender: user.id!,comment: "<a href=\"\(user.getURL())\">\(user.fullname) </a> added a photo to trip <a href=\"\(trip.getURL())\">\(trip.name)</a>")
        
        try notification.sendNotificationTo(users: try trip.attendees.all().array, skipSender: user.id!)
        
        
//        for attendee in try trip.attendees.all().enumerated() {
//            if (attendee.element.id! != user.id!){
//                let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, receiver: attendee.element.id!, sender: user.id!)
//                notification.comment = "<a href=\"\(user.getURL())\">\(user.fullname) </a> added a photo to trip <a href=\"\(trip.getURL())\">\(trip.name)</a>"
//                try notification.save()
//            }
//        }
        
        let notif = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, sender: user.id!)
        notif.comment = "<a href=\"\(user.getURL())\">\(user.fullname)</a> added a photo to trip <a href=\"\(trip.getURL())\">\(trip.name)</a>"
        try trip.sendFollowersNotification(notification: notif, sender: user.id!, skipUser: user.id!)
        
//        for follower in trip.followers.enumerated() {
//            let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, receiver: try follower.element.getFollowerUser().id!, sender: user.id!)
//            notification.comment =
//            try notification.save()
//        }
        
        try flash?.addFlash(flashType: .success, message: "Photo added to the trip!")
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

        for attendee in try trip.attendees.all().enumerated() {
            let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, receiver: attendee.element.id!, sender: user.id!)
            notification.comment = "<a href=\"\(user.getURL())\">\(user.fullname)</a> added a comment to trip <a href=\"\(trip.getURL())\">\(trip.name)</a>"
            try notification.save()
        }
        
        for follower in trip.followers.enumerated() {
            let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, receiver: try follower.element.getFollowerUser().id!, sender: user.id!)
            notification.comment = "<a href=\"\(user.getURL())\">\(user.fullname)</a> added a comment to trip <a href=\"\(trip.getURL())\">\(trip)</a>"
            try notification.save()
        }
        
        try flash?.addFlash(flashType: .success, message: "Comment added to the trip!")
        return try ViewCache.instance.back(request: request)
    }
    
    func addAttendant(request: Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        
        guard let trip = try? request.parameters.next(Trip.self) else {
            try flash?.addFlash(flashType: .error, message: "Trip couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        guard let name = request.formData?["search"]?.string else {
            throw Abort(.badRequest, reason: "No user added?! 😱")
        }
       
        let nameString = name.trimmingCharacters(in: ["@"])
        guard let attendant = try User.makeQuery().filter("username", .equals, nameString).first() else {
            try flash?.addFlash(flashType: .error, message: "No user with username \(nameString) found")
            return try ViewCache.instance.back(request: request)
        }
        
        if try trip.attendees.isAttached(attendant) {
            try flash?.addFlash(flashType: .error, message: "User \(nameString) is already added to the trip")
            return try ViewCache.instance.back(request: request)
        }
        let user = try request.user()
        
        let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, receiver: attendant.id!, sender: user.id!)
        notification.comment = "You were added to the trip <a href=\"\(trip.getURL())\">\(trip.name)</a> by <a href=\"\(user.getURL())\">\(user.fullname)</a>"
        try notification.save()
        
        var notifyUser = [Identifier]()
        
        notifyUser.append(attendant.id!)
        notifyUser.append(user.id!)
        
        for attendee in try trip.attendees.all().enumerated() {
            if !notifyUser.contains(attendee.element.id!){
                let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, receiver: attendee.element.id!, sender: user.id!)
                notification.comment = "<a href=\"\(attendant.getURL())\">\(attendant.fullname)</a> were added to the trip <a href=\"\(trip.getURL())\">\(trip.name)</a> by <a href=\"\(user.getURL())\">\(user.fullname)</a>"
                try notification.save()
                notifyUser.append(attendee.element.id!)
            }
        }
        
        
        for follower in trip.followers.enumerated() {
            if !notifyUser.contains(try follower.element.getFollowerUser().id!){
                let notification = Notification.init(relatedObject: trip.objectType, relatedObjectId: trip.objectIdentifier, receiver: try follower.element.getFollowerUser().id!, sender: user.id!)
                notification.comment = "<a href=\"\(attendant.getURL())\">\(try follower.element.getFollowerUser().fullname)</a>\(try follower.element.getFollowerUser().fullname) were added to the trip <a href=\"\(trip.getURL())\">\(trip.name)</a> by <a href=\"\(user.getURL())\">\(user.fullname)</a>"
                try notification.save()
                notifyUser.append(follower.element.id!)
            }
        }
        
        try trip.attendees.add(attendant)
        try trip.save()
        
        try flash?.addFlash(flashType: .success, message: "\(nameString) added to the trip!")
        //return try ViewCache.instance.back(request: request)
        return try viewFactory.renderView(path: "Trip/trip_details", request: request, parameters:  ["trip" : try trip.makeJSON()
            ])
    }
    
    func viewTrip(request: Request) throws -> ResponseRepresentable {
//        TODO validate if i should be able to see this trip?
        
//        let file = try File.find(3)
//        let place = try Place.init(fromFile: file!)
        let flash = FlashMessage.init(request: request)

        guard let trip = try? request.parameters.next(Trip.self) else {
            try flash?.addFlash(flashType: .error, message: "Trip couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        return try viewFactory.renderView(path: "Trip/trip_details", request: request, parameters:  ["trip" : try trip.makeJSON()
            ])
    }
    
    func createTrip(request: Request) throws -> ResponseRepresentable {
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
        var sdate : Double?
        var edate : Double?
        
        sdate = dateFormatter.date(from: startdate)?.timeIntervalSince1970
        if sdate == nil {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            sdate = dateFormatter.date(from: startdate)?.timeIntervalSince1970
        }
        
        edate = dateFormatter.date(from: enddate)?.timeIntervalSince1970
        if edate == nil {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            edate = dateFormatter.date(from: enddate)?.timeIntervalSince1970
        }

        let trip = try Trip.createTrip(name: name, tripStart: sdate!, tripEnd: edate!, createdBy: user.id!, description: description)
        
        let flash = FlashMessage.init(request: request)
        try flash?.addFlash(flashType: .success, message: "Trip created!")
        //return try ViewCache.instance.back(request: request)
        return try viewFactory.renderView(path: "Trip/trip_details", request: request, parameters:  ["trip" : try trip.makeJSON()
            ])
    }
    
    func createTripView(request: Request) throws -> ResponseRepresentable {
        return try viewFactory.renderView(path: "Trip/trip_create", request: request)
    }
    
    func feedAddEnvy(request: Request) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        guard let feed = try? request.parameters.next(Feed.self) else {
            try flash?.addFlash(flashType: .error, message: "Feed couldnt be found.")
            return try ViewCache.instance.back(request: request)
        }
        
        let user = try request.user()
        
        if try feed.isObjectEnviedBy(user: user.id!){
            try flash?.addFlash(flashType: .error, message: "You have already envied this feed")
            return try ViewCache.instance.back(request: request)
        }else {
            try feed.addEnvyBy(user: user)
            return try ViewCache.instance.back(request: request)
        }
    }
    
    func feedAddComment(request: Request ) throws -> ResponseRepresentable {
        let flash = FlashMessage.init(request: request)
        guard let feed = try? request.parameters.next(Feed.self) else {
            return Response(status: .found, headers: ["Location": "/"])
        }
        guard let comment = request.formData!["comment"]?.string! else {
            try flash?.addFlash(flashType: .error, message: "Comment couldnt be added")
            return try ViewCache.instance.back(request: request)
        }
        
        if comment.count < 1 {
            try flash?.addFlash(flashType: .error, message: "Comment has to be atleast 1 character long")
            return try ViewCache.instance.back(request: request)
        }
        
        let user = try request.user()
        
        try _ = feed.addComment(by: user.id!, commment: comment)
        return try ViewCache.instance.back(request: request)
    }
}
