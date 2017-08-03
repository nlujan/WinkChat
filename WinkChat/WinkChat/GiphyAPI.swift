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
    static func getRandomGifFrom(text: String) -> Observable<Gif?>
    static func getSearchGifsFrom(text: String) -> Observable<[Gif]?>
}

struct GiphyAPI: GiphyProtocol {
    
    private static let provider: RxMoyaProvider<Giphy> = RxMoyaProvider<Giphy>()
    
    static func getRandomGifFrom(text: String) -> Observable<Gif?> {
        return provider
            .request(Giphy.Random(searchText: text))
            .mapObjectOptional(type: Gif.self, keyPath: "data")
    }
    
    static func getSearchGifsFrom(text: String) -> Observable<[Gif]?> {
        return provider
            .request(Giphy.Search(searchText: text))
            .mapArrayOptional(type: Gif.self, keyPath: "data")
    }
}


