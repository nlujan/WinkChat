//
//  ViewModel.swift
//  WinkChat
//
//  Created by Naim Lujan on 6/25/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation
import RxSwift
import RxOptional

class GifViewModel {
    
    private let disposeBag = DisposeBag()
    
    // Inputs
    let randomUrlSubject = PublishSubject<URL>()
    let searchUrlSubject = PublishSubject<URL>()
    
    // Outputs
    let randomGifSubject = PublishSubject<Gif>()
    let searchGifsSubject = PublishSubject<[Gif]>()
    let errorSubject = PublishSubject<Error>()

    init() {
        bindOutput()
    }
    
    private func bindOutput() {
        
        randomUrlSubject
            .flatMap { [unowned self] url in
                self.getEmotionString(url: url)
            }
            .flatMap { searchText in
                GiphyAPI.getRandomGifFrom(text: searchText)
            }
            .subscribe(onNext: { [unowned self] gif in
                if let g = gif {
                    self.randomGifSubject.onNext(g)
                } else {
                    self.errorSubject.onNext(APIError.NoGifRecieved)
                }
            })
            .disposed(by: disposeBag)
        
        searchUrlSubject
            .flatMap { [unowned self] url in
                self.getEmotionString(url: url)
            }
            .flatMap { searchText in
                GiphyAPI.getSearchGifsFrom(text: searchText)
            }        
            .subscribe(onNext: { [unowned self] gifData in
                if let gifs = gifData, gifs.count > 0 {
                    self.searchGifsSubject.onNext(gifs)
                } else {
                    self.errorSubject.onNext(APIError.NoGifRecieved)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func getEmotionString(url: URL) -> Observable<String> {
        return Observable.from(optional: url)
            .flatMap { url in
                EmotionAPI.getEmotion(from: url)
            }
            .do(onNext: { [unowned self] emotionArray in
                if emotionArray == nil {
                    self.errorSubject.onNext(APIError.NoGifRecieved)
                } else if emotionArray?.count == 0  {
                    self.errorSubject.onNext(APIError.NoFaceDetected)
                }
            })
            .filterNil()
            .filter { $0.count > 0 }
            .map { $0[0] }
            .map { $0.scores }
            .map { scores -> String in
                let max = scores.values.max()
                return scores.filter { $0.1 == max }.first!.key
            }
            .map { $0 == "neutral" ? "bored" : $0 }
    }
    
}

enum APIError: Error {
    case NoFaceDetected
    case NoGifRecieved
}
