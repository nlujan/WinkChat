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
    static func getEmotion(from imageUrl: URL) -> Observable<[Emotion]?>
}

struct EmotionAPI: EmotionProtocol {
    
    private static let provider: MoyaProvider<EmotionEndpoint> = MoyaProvider<EmotionEndpoint>(endpointClosure: { (target: EmotionEndpoint) -> Endpoint<EmotionEndpoint> in
        let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
        return defaultEndpoint.adding(newHTTPHeaderFields: ["Content-Type": "application/octet-stream", "Ocp-Apim-Subscription-Key": Constants.Emotion.Key])
    })
    
    static func getEmotion(from imageUrl: URL) -> Observable<[Emotion]?> {
        return provider.rx
            .request(.Recognize(imageUrl: imageUrl)).asObservable()
            .mapOptional(to: [Emotion].self)
            .timeout(Constants.Timeout, scheduler: MainScheduler.instance)
            .catchError { error in
                Observable.just(nil)
        }
    }
}

