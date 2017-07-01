//
//  Gif.swift
//  WinkChat
//
//  Created by Naim Lujan on 6/25/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Mapper

struct Gif: Mappable {
    
    let id: String
    let image_url: String
    let fixed_height_downsampled_url: String
    let fixed_height_small_url: String
    
    init(map: Mapper) throws {
        try id = map.from("id")
        try image_url = map.from("image_url")
        try fixed_height_downsampled_url = map.from("fixed_height_downsampled_url")
        try fixed_height_small_url = map.from("fixed_height_small_url")
    }
    
}
