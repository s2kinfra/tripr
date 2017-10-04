import Vapor
import LeafProvider
import MapKit

final class Routes: RouteCollection {
    
    let drop : Droplet
    let viewFactory : LeafViewFactory
    
    
    init(drop : Droplet) {
        self.drop = drop
        self.viewFactory = LeafViewFactory(viewRenderer: drop.view)
        if let leaf = drop.view as? LeafRenderer {
//            LeafSocialTags(stem:leaf.stem).registerSocialTags()
        }
        
    }
    
    func build(_ builder: RouteBuilder) throws {
        
        try builder.collection(RoutesView.init(drop: self.drop))
//        try builder.collection(RoutesApi.self)
    }
}
