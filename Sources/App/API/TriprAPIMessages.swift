//
//  TriprAPIMessages.swift
//  triprIOS
//
//  Created by Daniel Skevarp on 2018-01-02.
//  Copyright © 2018 Daniel Skevarp. All rights reserved.
//

import Foundation


enum httpMethod : String {
    case POST = "POST", GET = "GET", PUT = "PUT", DELETE = "DELETE"
}

enum httpContentTypes : String {
    case json = "application/json",
    www_form = "application/x-www-form-urlencoded",
    form_data = "multipart/form-data"
    
    var string : String { get { return self.rawValue } }
}

enum TriprAPIMessagePriority : Int {
    case low = 0, medium, high
}

struct triprAPIMessage {
    var messageId: String
    var contentType: httpContentTypes
    var timestamp: Double
    var payload: String
    var URL: String
    var queable: Bool
    var priority: TriprAPIMessagePriority
    var sent: Bool
    var reference : String?
    var httpMethod : httpMethod
    var attachment : Data?
    
    init?(payload : String, httpMethod : httpMethod, contentType: httpContentTypes, URL : String, quable : Bool, priority : TriprAPIMessagePriority) {
            self.timestamp = Date().timeIntervalSince1970
            self.payload = payload
            self.sent = false
            self.contentType = contentType
            self.httpMethod = httpMethod
            self.URL = URL
            self.queable = quable
            self.priority = priority
            self.messageId = UUID.init().uuidString
    }
}

