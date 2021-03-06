//
//  GiphyEnpoint.swift
//  WinkChat
//
//  Created by Naim Lujan on 6/25/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation
import Moya


enum Giphy {
    case Search(searchText: String)
    case Random(searchText: String)
}

extension Giphy: TargetType {
    var baseURL: URL {
        return URL(string: "https://api.giphy.com")!
    }
    
    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String {
        switch self {
        case .Search: return "/v1/gifs/search"
        case .Random: return "/v1/gifs/random"
        }
    }
    
    /// The HTTP method used in the request.
    var method: Moya.Method {
        return .get
    }
    
    /// The parameters to be incoded in the request.
    var headers: [String: String]? {
        switch self {
        case .Search(let searchText):
            return ["api_key": Constants.Giphy.Key, "q": searchText, "offset": String(arc4random_uniform(100)), "rating": "g"]
        case .Random(let searchText):
            return ["api_key": Constants.Giphy.Key, "tag": searchText, "rating": "g"]
        }
    }
    
    /// The method used for parameter encoding.
    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    /// Provides stub data for use in testing.
    var sampleData: Data {
        return Data()
    }
    
    /// The type of HTTP task to be performed.
    var task: Task {
        return .requestParameters(parameters: headers!, encoding: parameterEncoding)
    }
    
}
