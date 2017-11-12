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
    
    private static let provider = MoyaProvider<Giphy>()
    
    static func getRandomGifFrom(text: String) -> Observable<Gif?> {
        return provider.rx
            .request(.Random(searchText: text)).asObservable()
            .mapOptional(to: Gif.self, keyPath: "data")
            .timeout(Constants.Timeout, scheduler: MainScheduler.instance)
            .catchErrorJustReturn(nil)
    }
    
    static func getSearchGifsFrom(text: String) -> Observable<[Gif]?> {
        return provider.rx
            .request(.Search(searchText: text)).asObservable()
            .mapOptional(to: [Gif].self, keyPath: "data")
            .timeout(Constants.Timeout, scheduler: MainScheduler.instance)
            .catchErrorJustReturn(nil)
    }
}
