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
    
    let imageUrl = PublishSubject<URL>()
    let gifSubject = PublishSubject<Gif?>()

    init() {
        bindOutput()
    }
    
    func bindOutput() {
        
        let urlSignal: Observable<Emotion> = imageUrl
            .flatMap { url in
                EmotionAPI.getEmotion(from: url)
            }
            .do(onNext: { emotionArray in
                if emotionArray.count == 0 {
                    self.gifSubject.onNext(nil)
                }
            })
            .filter { $0.count > 0 }
            .map { $0[0] }
        
        urlSignal
            .map { $0.scores }
            .map { scores in
                scores.keys.map { ($0, scores[$0]!) }
            }
            .map { tupleArray in
                tupleArray.sorted {$0.1 > $1.1}
            }
            .map { $0.first }
            .filterNil()
            .map { $0.0 }
            .flatMap { searchText in
                GiphyAPI.getGifFrom(text: searchText)
            }
            .filterNil()
            .subscribe(onNext: { gif in
                self.gifSubject.onNext(gif)
            })
            .disposed(by: bag)
    }
}

enum EmotionError: Error {
    case NoFaceDetected
}

enum GiphyError: Error {
}
