//
//  GiphyAPI.swift
//  WinkChat
//
//  Created by Naim Lujan on 6/25/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation
import Moya
import RxOptional
import RxSwift

protocol GiphyProtocol {
    static func getGifFrom(text: String) -> Observable<Gif?>
}

struct GiphyAPI: GiphyProtocol {
    
    static let provider: RxMoyaProvider<Giphy> = RxMoyaProvider<Giphy>()
    
    static func getGifFrom(text: String) -> Observable<Gif?> {
        return provider
            .request(Giphy.Random(searchText: text))
            .debug()
            .mapObjectOptional(type: Gif.self, keyPath: "data")
    }
}
