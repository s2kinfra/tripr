//
//  LeafFunctions.swift
//  App
//
//  Created by Daniel Skevarp on 2017-10-10.
//

import Foundation
import Leaf
import Node

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
            var isFollowing : Bool = false
            for follow in me.following {
                if follow.objectId == follower.id! {
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

