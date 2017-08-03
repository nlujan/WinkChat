//
//  EmotionAPI.swift
//  WinkChat
//
//  Created by Naim Lujan on 6/25/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation
import Moya
import Mapper
import Moya_ModelMapper
import RxOptional
import RxSwift

protocol EmotionProtocol {
    static func getEmotion(from imageUrl: URL) -> Observable<[Emotion]>
}

struct EmotionAPI: EmotionProtocol {
    
    private static let provider: RxMoyaProvider<EmotionEndpoint> = RxMoyaProvider<EmotionEndpoint>(endpointClosure: { (target: EmotionEndpoint) -> Endpoint<EmotionEndpoint> in
        let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
        return defaultEndpoint.adding(newHTTPHeaderFields: ["Content-Type": "application/octet-stream", "Ocp-Apim-Subscription-Key": Constants.Emotion.Key])
    })
    
    static func getEmotion(from imageUrl: URL) -> Observable<[Emotion]> {
        return provider
            .request(EmotionEndpoint.Recognize(imageUrl: imageUrl))
            .mapArrayOptional(type: Emotion.self)
            .replaceNilWith([])
    }
}

