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
    let height: String
    let width: String
    
    init(map: Mapper) throws {
        try id = map.from("id")
        do {
            try image_url = map.from("image_url")
        } catch {
            try image_url = map.from("images.downsized_medium.url")
        }
        do {
            try height = map.from("image_height")
        } catch {
            try height = map.from("images.downsized_medium.height")
        }
        do {
            try width = map.from("image_width")
        } catch {
            try width = map.from("images.downsized_medium.width")
        }
    }
}

