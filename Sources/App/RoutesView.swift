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
                    let user = try req.user()
                    return try self.viewFactory.renderView(path: "Home/home", request: req,parameters:["trips" : try Trip.getTripsFor(user: user.id!).sorted(by: {$0.createdAt! > $1.createdAt!	}).makeJSON(),
                                                                                                       "ftrips": try user.getFollowedTrips().makeJSON()])
                }
                return try self.viewFactory.renderView(path: "index", request: req)
            }
        builder.get("register") { req in
            return try self.viewFactory.renderView(path: "register", request: req)
        }
            
            //User
            let userController = UserController(viewFactory: self.viewFactory)
            userController.addRoutes(drop: drop)
            //trip
            let tripController = TripController(viewFactory: self.viewFactory)
            tripController.addRoutes(drop: drop)
            //search
            let searchController = SearchController(viewFactory: self.viewFactory)
            searchController.addRoutes(drop: drop)
//          Places
            let placeController = PlaceController(viewFactory: self.viewFactory)
            placeController.addRoutes(drop: drop)
        
    }
}
