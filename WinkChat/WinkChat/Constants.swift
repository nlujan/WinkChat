//
//  Constants.swift
//  MessagesExtension
//
//  Created by Naim Lujan on 8/3/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation

struct Constants {
    
    struct Giphy {
        static let Url = "www.giphy.com"
        static let Key = "dc6zaTOxFJmzC"
    }
    struct Emotion {
        static let Key = "aa26cb41fc1c48d29d8d08fabe3a23a7"
        static let Default = "happiness"
    }
    
    
    static let GifFilename = "gifFile.gif"
    static let ImageFilename = "image.png"
    static let Timeout = 8.0
    
    struct ErrorMessage {
        static let NetworkIssue = "Network issue, please check connection and try again"
        static let NoFaceDetected = "No face detected, please try again"
    }
    
    //"No face detected, please try again"
    //"Network issue, please check connection and try again"
    //"No internet connection found, please reconnect and try again"
}
