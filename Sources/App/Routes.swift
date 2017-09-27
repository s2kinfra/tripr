import Vapor

extension Droplet {
    func setupRoutes() throws {
        get("hello") { req in
            var json = JSON()
            try json.set("hello", "world")
            return json
        }

        get("plaintext") { req in
            return "Hello, world!"
        }

        // response to requests to /info domain
        // with a description of the request
        get("info") { req in
            return req.description
        }

        get("description") { req in return req.description }
        
        try resource("posts", PostController.self)
        
//        let user = User.init()
//        user.email = "test@test.com"
//        user.username = "test"
//        user.password = try User.passwordHasher.make("test")
//        try user.save()
//
//        let user2 = User.init()
//        user2.email = "test2@test.com"
//        user2.username = "test2"
//        user2.password = try User.passwordHasher.make("test2")
//        try user2.save()
//
//        try user.startFollowing(by: user2.id!)
//
//        try user.acceptFollow(follower: user2.id!)
//
//        for follower in user.followers {
//            print(try follower.getFollowerUser().email)
//        }
        
    }
}
