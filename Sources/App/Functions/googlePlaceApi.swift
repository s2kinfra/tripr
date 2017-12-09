//
//  googlePlaceApi.swift
//  App
//
//  Created by Daniel Skevarp on 2017-11-01.
//

import Foundation

struct ApiData : Codable {
    var name : String
    var place_id : String
    var vicinity : String
    var types : [String]
}
struct ApiResult : Codable{
    
    var results : [ApiData]
    
    //    enum ProductKeys: String, CodingKey {
    //        case results
    //    }
    //
    //    enum CodingKeys: String, CodingKey {
    //        case name
    //        case place_id
    //        case vicinity
    //
    //    }
    //
    //    public init(from decoder: Decoder) throws {
    //        let values = try decoder.container(keyedBy: ProductKeys.self)
    //        let productValues = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .results)
    //        print(values)
    //        print(productValues)
    //        name = try productValues.decode(String.self, forKey: .name)
    //        place_id = try productValues.decode(String.self, forKey: .place_id)
    //        vicinity = try productValues.decode(String.self, forKey: .vicinity)
    //
    //    }
    
}

