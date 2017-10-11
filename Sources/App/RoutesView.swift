import Vapor
import LeafProvider
import AuthProvider
import MySQL

final class RoutesView: RouteCollection {
    
    let drop : Droplet
    let viewFactory : LeafViewFactory
    
    
    init(drop : Droplet) {
        self.drop = drop
        self.viewFactory = LeafViewFactory(viewRenderer: drop.view)
    }
    
    func build(_ builder: RouteBuilder) throws {
        
        
            // root
            builder.get("") { req in
                if req.auth.isAuthenticated(User.self) {
                    return try self.viewFactory.renderView(path: "Home/home", request: req, parameters:  ["timeline" : try req.user().getFeedObjects(limit: 20) ])
                }
                return try self.viewFactory.renderView(path: "index", request: req)
            }
        builder.get("register") { req in
            return try self.viewFactory.renderView(path: "register", request: req)
        }
            
            //User
            let userController = UserController(viewFactory: self.viewFactory)
            userController.addRoutes(drop: drop)
            
//            //Search
//            let searchController = SearchController(viewFactory: self.viewFactory)
//            searchController.addRoutes(drop: drop)
//            let passmw = PasswordAuthenticationMiddleware(User.self)
//            let tripController = TripController(viewFactory: self.viewFactory)
//            tripController.addRoutes(drop: drop)
//            //drop.middleware.append(tokenMiddleware)
//            let socialController = SocialController(viewFactory: self.viewFactory)
//            socialController.addRoutes(drop: drop)
//            builder.group(passmw) { request in
//                request.get("secure") { request in
//                    return try request.user().firstname
//                }
//            }
        
    }
}
