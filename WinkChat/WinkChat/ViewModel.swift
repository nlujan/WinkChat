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
    
    // MARK: - Input
    let imageUrl = PublishSubject<URL>()
    
    // MARK: - Output
    let gifSubject = PublishSubject<Gif>()
    let emotionSubject = PublishSubject<Emotion>()
    
    
    // MARK: - Init
    
    init() {
        bindOutput()
    }
    
    func bindOutput() {
        
        let urlSignal: Observable<Emotion> = imageUrl
            .flatMap { url in
                EmotionAPI.getEmotion(from: url)
            }
            .filter { $0.count > 0 }
            .map { $0[0] }
            .shareReplay(1)
        
        
        urlSignal
            .subscribe(onNext: {emotion in
                self.emotionSubject.onNext(emotion)
            })
            .disposed(by: bag)
        
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
            .debug()
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
