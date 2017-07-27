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
    
    private let bag = DisposeBag()
    
    let imageUrlSubject = PublishSubject<URL>()
    let gifSubject = PublishSubject<Gif>()
    let errorSubject = PublishSubject<Error>()

    init() {
        bindOutput()
    }
    
    func bindOutput() {
        
        let emotionSignal: Observable<Emotion> = imageUrlSubject
            .flatMap { url in
                EmotionAPI.getEmotion(from: url)
            }
            .do(onNext: { emotionArray in
                if emotionArray.count == 0 {
                    self.errorSubject.onNext(EmotionError.NoFaceDetected)
                }
            })
            .filter { $0.count > 0 }
            .map { $0[0] }
        
        emotionSignal
            .map { $0.scores }
            .map { scores -> String in
                let max = scores.values.max()
                return scores.filter { $0.1 == max }.first!.key
            }
            .flatMap { searchText in
                GiphyAPI.getGifFrom(text: searchText)
            }
            .subscribe(onNext: { gif in
                if let g = gif {
                    self.gifSubject.onNext(g)
                } else {
                    self.errorSubject.onNext(GiphyError.NoGifRecieved)
                }
            })
            .disposed(by: bag)
    }
}

enum EmotionError: Error {
    case NoFaceDetected
}

enum GiphyError: Error {
    case NoGifRecieved
}

enum ReachabilityError: Error {
    case NoInternectConnection
}
