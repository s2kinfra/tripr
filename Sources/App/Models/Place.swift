//
//  Place.swift
//  App
//
//  Created by Daniel Skevarp on 2017-09-20.
//

import Foundation

struct Adress {
    var street : String
    var houseNumber: Int
    var city : String
    var country : String
}

class Place {
    
    var longitude : Double?
    var latitude : Double?
    var name : String?
    var country : String?
    var city : String?
    var adress : Adress?
    var temperature : String?
    
    
}
