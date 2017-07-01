//
//  Emotion.swift
//  WinkChat
//
//  Created by Naim Lujan on 6/25/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Mapper

struct Emotion: Mappable {
    
    let scores: [String: Double]
    
    init(map: Mapper) throws {
        try scores = map.from("scores")
    }
}
