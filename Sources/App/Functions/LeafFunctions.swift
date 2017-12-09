//
//  LeafFunctions.swift
//  App
//
//  Created by Daniel Skevarp on 2017-10-10.
//

import Foundation
import Leaf
import Node
import Vapor

struct LeafFunctions {
    
    var stem : Stem
    
    init(stem : Stem) {
        self.stem = stem
    }
    
    func registerLeafFunctions() {
//        self.stem.register(LeafIsFollowing())
        self.stem.register(LeafIsFollowing())
        self.stem.register(LeafTimeAgo())
        self.stem.register(LeafTriprEquals())
        self.stem.register(LeafCountTag())
        self.stem.register(LeafDoubleDate())
        self.stem.register(LeafIsRequestingFollow())
        self.stem.register(LeafUser())
        self.stem.register(LeafTrip())
        self.stem.register(LeafFile())
        self.stem.register(LeafComment())
        self.stem.register(LeafCommentable())
        self.stem.register(LeafIsEnvied())
        self.stem.register(LeafObject())
        self.stem.register(LeafLink())
        self.stem.register(LeafHTML())

    }
        
    
    fileprivate static func fuzzyEquals(_ lhs: Node?, _ rhs: Node?) -> Bool {
        let lhs = lhs ?? .null
        let rhs = rhs ?? .null
        
        switch lhs.wrapped {
        case let .array(lhs):
            guard let rhs = rhs.array else { return false }
            guard lhs.count == rhs.count else { return false }
            for (l, r) in zip(lhs, rhs) where !fuzzyEquals(Node(l), r) { return false }
            return true
        case let .bool(bool):
            return bool == rhs.bool
        case let .bytes(bytes):
            guard case let .bytes(rhs) = rhs.wrapped else { return false }
            return bytes == rhs
        case .null:
            return rhs.isNull
        case let .number(number):
            switch number {
            case let .double(double):
                return double == rhs.double
            case let .int(int):
                return int == rhs.int
            case let .uint(uint):
                return uint == rhs.uint
            }
        case let .object(lhs):
            guard let rhs = rhs.object else { return false }
            guard lhs.count == rhs.count else { return false }
            for (k, v) in lhs where !fuzzyEquals(Node(v), rhs[k]) { return false }
            return true
        case let .string(string):
            return string == rhs.string
        case let .date(date):
            // FIXME: Add fuzzy date access and equality?
            guard case let .date(right) = rhs.wrapped else { return false }
            return date == right
        }
    }
    
    
}

public enum Error: Swift.Error {
    case expectedOneArguments(have: ArgumentList)
    case expectedVariable(have: ArgumentList)
    case expectedTwoArguments(have: ArgumentList)
    case expectedConstant(have: ArgumentList)
    case customString(message: String)
}

class LeafHTML: Tag {
    public let name = "html"
    
    func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
        ) -> Bool {
        
        return true
        
    }
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 1 else { throw Error.expectedTwoArguments(have: arguments) }
        
        var urltext = ""
        
        let variable = arguments.list[0]
        if case let .variable(path: _, value: value) = variable {
            urltext = (value?.string!)!
        }else {
            let constant2 = arguments.list[0]
            guard case let .constant(value: urlnote) = constant2 else {
                throw Error.expectedConstant(have: arguments)
            }
            urltext = urlnote.raw
        }
        
        
        return Node.string(urltext, in: nil)
    }
    
    public func render(
        stem: Stem,
        context: LeafContext,
        value: Node?,
        leaf: Leaf
        ) throws -> Bytes {
        
        return (value?.bytes)!
    }
}

class LeafLink : Tag {
    public let name = "link"
    
    func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
        ) -> Bool {
        
        return true
        
    }
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments) }

        let constant1 = arguments.list[0]
        guard case let .constant(value: url) = constant1 else {
            throw Error.expectedConstant(have: arguments)
        }
        
        let constant2 = arguments.list[1]
        guard case let .constant(value: urlText) = constant2 else {
            throw Error.expectedConstant(have: arguments)
        }
        
        
        return Node.string("<a href=\"\(url.raw)\">\(urlText.raw)</a>", in: nil)
    }
    
    public func render(
        stem: Stem,
        context: LeafContext,
        value: Node?,
        leaf: Leaf
        ) throws -> Bytes {
        
        return (value?.bytes)!
    }
}

class LeafObject : Tag {
    public let name = "object"
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 3 else { throw Error.expectedTwoArguments(have: arguments) }
        let variable = arguments.list[0]
        guard case let .variable(path: _, value: value) = variable else {
            throw Error.expectedVariable(have: arguments)
        }
        
        guard let objectType = value?.wrapped.string else {
            throw Error.expectedVariable(have: arguments)
        }
        
        let constant = arguments.list[1]
        guard case let .variable(path: _, value: value2) = constant else {
            throw Error.expectedVariable(have: arguments)
        }
        guard let objectId = value2?.wrapped.int else {
            throw Error.expectedVariable(have: arguments)
        }
        
        let constant2 = arguments.list[2]
        guard case let .constant(value: leaf2) = constant2 else {
            throw Error.expectedConstant(have: arguments)
        }
        
        let innername = try arguments.stem
            .render(leaf2, with: arguments.context)
            .makeString()
        
        let object : JSON
        switch objectType {
        case "App.Trip":
            object = (try Trip.find(objectId)?.makeJSON())!
        case "App.User":
            object = (try User.find(objectId)?.makeJSON())!
        case "App.File":
            object = (try File.find(objectId)?.makeJSON())!
        case "App.Comment":
            object = (try Comment.find(objectId)?.makeJSON())!
        default:
            throw Error.expectedConstant(have: arguments)
        }
        
        let unwrapped = object.makeNode(in: nil) 
        let array = unwrapped.array ?? [unwrapped]
        let nodes = try array.enumerated().map { idx, val in
            return try Node(
                node: [
                    innername: object,
                    "index": idx,
                    "offset": idx + 1
                ]
            )
        }
        return .array(nodes)
    }
    
    public func render(
        stem: Stem,
        context: LeafContext,
        value: Node?,
        leaf: Leaf
        ) throws -> Bytes {
        guard let array = value?.array else { fatalError("run function MUST return an array") }
        func renderItem(_ item: Node) throws -> Bytes {
            context.push(item)
            let rendered = try stem.render(leaf, with: context)
            context.pop()
            return rendered
        }
        return try array.map(renderItem)
            .joined(separator: [.newLine])
            .flatMap { $0 }
    }
}

class LeafComment : Tag {
    
    //    Get User object from ID
    
    public let name = "comment"
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments) }
        let variable = arguments.list[0]
        guard case let .variable(path: _, value: value) = variable else {
            throw Error.expectedVariable(have: arguments)
        }
        let constant = arguments.list[1]
        guard case let .constant(value: leaf) = constant else {
            throw Error.expectedConstant(have: arguments)
        }
        let innername = try arguments.stem
            .render(leaf, with: arguments.context)
            .makeString()
        
        guard let unwrapped = value else { return nil }
        let array = unwrapped.array ?? [unwrapped]
        let nodes = try array.enumerated().map { idx, val in
            return try Node(
                node: [
                    innername: try Comment.find(val.int)!.makeJSON(),
                    "index": idx,
                    "offset": idx + 1
                ]
            )
        }
        return .array(nodes)
    }
    
    public func render(
        stem: Stem,
        context: LeafContext,
        value: Node?,
        leaf: Leaf
        ) throws -> Bytes {
        guard let array = value?.array else { fatalError("run function MUST return an array") }
        func renderItem(_ item: Node) throws -> Bytes {
            context.push(item)
            let rendered = try stem.render(leaf, with: context)
            context.pop()
            return rendered
        }
        return try array.map(renderItem)
            .joined(separator: [.newLine])
            .flatMap { $0 }
    }
    
}

class LeafFile : Tag {
    
    //    Get User object from ID
    
    public let name = "file"
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments) }
        let variable = arguments.list[0]
        guard case let .variable(path: _, value: value) = variable else {
            throw Error.expectedVariable(have: arguments)
        }
        let constant = arguments.list[1]
        guard case let .constant(value: leaf) = constant else {
            throw Error.expectedConstant(have: arguments)
        }
        let innername = try arguments.stem
            .render(leaf, with: arguments.context)
            .makeString()
        
        guard let unwrapped = value else { return nil }
        let array = unwrapped.array ?? [unwrapped]
        let nodes = try array.enumerated().map { idx, val in
            return try Node(
                node: [
                    innername: try File.find(val.int)!.makeJSON(),
                    "index": idx,
                    "offset": idx + 1
                ]
            )
        }
        return .array(nodes)
    }
    
    public func render(
        stem: Stem,
        context: LeafContext,
        value: Node?,
        leaf: Leaf
        ) throws -> Bytes {
        guard let array = value?.array else { fatalError("run function MUST return an array") }
        func renderItem(_ item: Node) throws -> Bytes {
            context.push(item)
            let rendered = try stem.render(leaf, with: context)
            context.pop()
            return rendered
        }
        return try array.map(renderItem)
            .joined(separator: [.newLine])
            .flatMap { $0 }
    }
    
}

class LeafTrip : Tag {
    
    //    Get User object from ID
    
    public let name = "trip"
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments) }
        let variable = arguments.list[0]
        guard case let .variable(path: _, value: value) = variable else {
            throw Error.expectedVariable(have: arguments)
        }
        let constant = arguments.list[1]
        guard case let .constant(value: leaf) = constant else {
            throw Error.expectedConstant(have: arguments)
        }
        let innername = try arguments.stem
            .render(leaf, with: arguments.context)
            .makeString()
        
        guard let unwrapped = value else { return nil }
        let array = unwrapped.array ?? [unwrapped]
        let nodes = try array.enumerated().map { idx, val in
            return try Node(
                node: [
                    innername: try Trip.find(val.int)!.makeJSON(),
                    "index": idx,
                    "offset": idx + 1
                ]
            )
        }
        return .array(nodes)
    }
    
    public func render(
        stem: Stem,
        context: LeafContext,
        value: Node?,
        leaf: Leaf
        ) throws -> Bytes {
        guard let array = value?.array else { fatalError("run function MUST return an array") }
        func renderItem(_ item: Node) throws -> Bytes {
            context.push(item)
            let rendered = try stem.render(leaf, with: context)
            context.pop()
            return rendered
        }
        return try array.map(renderItem)
            .joined(separator: [.newLine])
            .flatMap { $0 }
    }
    
}

class LeafIsEnvied : Tag {
    
    public let name = "isEnvied"
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments) }
        return nil
    }
    
    func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
        ) -> Bool {
        
        let enviedObject = arguments.first?.object
        let envyUser = arguments.last?.int
        
        var envied : Bool = false
        
        for envy in (enviedObject!["envies"]?.array)! {
            let enviedBy = envy.object!["enviedBy"]?.int
            if enviedBy == envyUser {
                envied = true
                break
            }
        }
        
        return envied
        
    }
}

class LeafCommentable : Tag {
    
    public let name = "feedCommentable"
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 1 else { throw Error.expectedTwoArguments(have: arguments) }
        return nil
    }
    
    func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
        ) -> Bool {
        
        let feedType = arguments.first
        
        switch feedType!.int! {
        case 1:
            return true
        case 20:
            return true
        case 10:
            return true
        case 11:
            return true
        case 30:
            return true
        default:
            return false
        }
       
    }
}

class LeafUser : Tag {
    
//    Get User object from ID
    
    public let name = "user"
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments) }
        let variable = arguments.list[0]
        guard case let .variable(path: _, value: value) = variable else {
            throw Error.expectedVariable(have: arguments)
        }
        let constant = arguments.list[1]
        guard case let .constant(value: leaf) = constant else {
            throw Error.expectedConstant(have: arguments)
        }
        let innername = try arguments.stem
            .render(leaf, with: arguments.context)
            .makeString()
        
        guard let unwrapped = value else { return nil }
        let array = unwrapped.array ?? [unwrapped]
        let nodes = try array.enumerated().map { idx, val in
            return try Node(
                node: [
                    innername: try User.find(val.int)!.makeJSON(),
                    "index": idx,
                    "offset": idx + 1
                ]
            )
        }
        return .array(nodes)
    }
    
    public func render(
        stem: Stem,
        context: LeafContext,
        value: Node?,
        leaf: Leaf
        ) throws -> Bytes {
        guard let array = value?.array else { fatalError("run function MUST return an array") }
        func renderItem(_ item: Node) throws -> Bytes {
            context.push(item)
            let rendered = try stem.render(leaf, with: context)
            context.pop()
            return rendered
        }
        return try array.map(renderItem)
            .joined(separator: [.newLine])
            .flatMap { $0 }
    }
   
}

class LeafTimeAgo : Tag {
    
//    Converts a date to timeago like 1h ago, 1 year ago etc
    
    public let name = "timeago"
    
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        let time = arguments.first?.date
        
        return time!.timeAgo(numericDates: true).makeNode(in: nil)
    }
    
}
class LeafCountTag : Tag {
//    Count an array
    public let name = "count"
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        
        let value = arguments.first
        guard let unwrapped = value?.array else {
            return 0
        }
        return unwrapped.count.makeNode(in: nil)
    }
}

class LeafDoubleDate : Tag {
// Convert a double date to readable date like 2017-10-01
    public let name = "date"
    
    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        
        
        //guard let value = arguments[0] else { return false }
        // Existence of bool, evaluate bool.
        guard let time = arguments.first?.date else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        let localDate = dateFormatter.string(from: time)
        
        return localDate.makeNode(in: nil)
    }
}

class LeafIsFollowing : BasicTag {
    
//    check if a user1 is following user2
    public let name = "isFollowing"
    
    func run(arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 3 else { throw Error.expectedTwoArguments(have: arguments) }
        return nil
    }
    
    func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
        ) -> Bool {
        
        //User id
        let constant1 = arguments.list[0]
        guard case let .variable(path: _, value: myId) = constant1 else {
            return false
        }
        guard let userId = myId?.wrapped.int else {
            return false
        }
        
        // Object Type
        let constant2 = arguments.list[1]
        guard case let .constant(value: leaf) = constant2 else {
            return false
        }
        
        let objectType = leaf.raw
        
        //object id
        let constant3 = arguments.list[2]
        guard case let .variable(path: _, value: objid) = constant3 else {
            return false
        }
        guard let objectId = objid?.wrapped.int else {
            return false
        }
        
        
        do {
            guard let me = try User.find(userId) else { return false }
            var isFollowing : Bool = false
            
            let fid = Identifier.string("\(objectId)")
            for follow in me.following {
                if (follow.objectId.int! == fid.int! && follow.object == objectType) {
                    isFollowing = true
                }
            }
            return isFollowing
        }catch {
            return false
        }
    }
}

class LeafTriprEquals : BasicTag {
    
//    equal function probably obsolete
    public let name = "triprEquals"
    
    func run(arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments) }
        return nil
    }
    
    func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
        ) -> Bool {
        
        return LeafFunctions.fuzzyEquals(arguments.first, arguments.last)
        
    }
}

class LeafIsRequestingFollow : BasicTag {
//    is user1 requesting follow of user2
    
    public let name = "isRequestingFollow"
    
    func run(arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments) }
        
        return nil
    }
    
    func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
        ) -> Bool {
        
        let myId = arguments.first
        let followId = arguments.last
        
        do {
            guard let me = try User.find(myId) else { return false }
            guard let follower = try User.find(followId) else { return false }
            var hasRequested : Bool = false
            
            for request in me.followingRequests {
                if request.objectId == follower.id! {
                    hasRequested = true
                }
            }
            return hasRequested
        }catch {
            return false
        }
        
    }
}

