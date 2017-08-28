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

class ViewModel {
    
    private let disposeBag = DisposeBag()
    
    // Inputs
    let randomUrlSubject = PublishSubject<URL>()
    let searchUrlSubject = PublishSubject<URL>()
    let searchTextSubject = PublishSubject<String>()
    
    // Outputs
    let randomGifSubject = PublishSubject<Gif>()
    let searchGifsSubject = PublishSubject<[Gif]>()
    let errorSubject = PublishSubject<Error>()

    init() {
        bindOutput()
    }
    
    func bindOutput() {
        
        searchTextSubject
            .flatMap { searchText in
                GiphyAPI.getSearchGifsFrom(text: searchText)
            }
            .subscribe(onNext: { gif in
                if let g = gif {
                    self.searchGifsSubject.onNext(g)
                } else {
                    self.errorSubject.onNext(APIError.NoGifRecieved)
                }
            })
            .disposed(by: disposeBag)
        
        randomUrlSubject
            .flatMap { url in
                self.getEmotionString(url: url)
            }
            .flatMap { searchText in
                GiphyAPI.getRandomGifFrom(text: searchText)
            }
            .subscribe(onNext: { gif in
                if let g = gif {
                    self.randomGifSubject.onNext(g)
                } else {
                    self.errorSubject.onNext(APIError.NoGifRecieved)
                }
            })
            .disposed(by: disposeBag)
        
        searchUrlSubject
            .flatMap { url in
                self.getEmotionString(url: url)
            }
            .flatMap { searchText in
                GiphyAPI.getSearchGifsFrom(text: searchText)
            }
            .subscribe(onNext: { gif in
                if let g = gif {
                    self.searchGifsSubject.onNext(g)
                } else {
                    self.errorSubject.onNext(APIError.NoGifRecieved)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func getEmotionString(url: URL) -> Observable<String> {
        return Observable.from(optional: url)
            .flatMap { url in
                EmotionAPI.getEmotion(from: url)
            }
            .do(onNext: { emotionArray in
                if emotionArray.count == 0 {
                    self.errorSubject.onNext(APIError.NoFaceDetected)
                }
            })
            .filter { $0.count > 0 }
            .map { $0[0] }
            .map { $0.scores }
            .map { scores -> String in
                print(scores) 
                let max = scores.values.max()
                return scores.filter { $0.1 == max }.first!.key
            }
            .map { emotion in
                if emotion == "neutral" {
                    return "bored"
                }
                return emotion
            }
    }
    
}

enum APIError: Error {
    case NoFaceDetected
    case NoGifRecieved
}
