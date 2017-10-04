@_exported import Vapor

extension Droplet {
    public func setup() throws {
        let routes = Routes.init(drop: self)
        try collection(routes)
        // Do any additional droplet setup
        
    }
}
