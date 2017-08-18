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
    let height: Int
    let width: Int
    
    init(map: Mapper) throws {
        try id = map.from("id")
        do {
            try image_url = map.from("image_url")
        } catch {
            try image_url = map.from("images.downsized_medium.url")
        }
        do {
            try height = map.from("image_height", transformation: convertToInt)
        } catch {
            try height = map.from("images.downsized_medium.height", transformation: convertToInt)
        }
        do {
            try width = map.from("image_width", transformation: convertToInt)
        } catch {
            try width = map.from("images.downsized_medium.width", transformation: convertToInt)
            
        }
    }
}

private func convertToInt(object: Any?) throws -> Int {
    
    guard let stringRep = object as? String else {
        throw MapperError.convertibleError(value: object, type: String.self)
    }
    
    guard let intRep = Int(stringRep) else {
        throw MapperError.customError(field: nil, message: "Couldn't convert string to int!")
    }
    
    return intRep
}

