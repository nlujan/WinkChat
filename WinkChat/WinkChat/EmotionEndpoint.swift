//
//  EmotionEndpoint.swift
//  WinkChat
//
//  Created by Naim Lujan on 6/25/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation
import Moya


enum EmotionEndpoint {
    case Recognize(imageUrl: URL)
}

extension EmotionEndpoint: TargetType {
    
    var baseURL: URL {
        return URL(string: "https://westus.api.cognitive.microsoft.com/emotion/v1.0")!
    }
    
    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String {
        switch self {
        case .Recognize: return "/recognize"
        }
    }
    
    /// The HTTP method used in the request.
    var method: Moya.Method {
        return .post
    }
    
    /// The parameters to be incoded in the request.
    var parameters: [String: Any]? {
        switch self {
        case .Recognize(_):
            return [:]
        }
    }
    
    /// The method used for parameter encoding.
    var parameterEncoding: ParameterEncoding {
        return JSONEncoding.default
    }
    
    /// Provides stub data for use in testing.
    var sampleData: Data {
        return Data()
    }
    
    /// The type of HTTP task to be performed.
    var task : Task {
        switch self {
        case .Recognize(let imageUrl):
            return .upload(UploadType.file(imageUrl))
        default:
            return .request
        }
    }
    
}

