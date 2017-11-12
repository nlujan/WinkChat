//
//  Constants.swift
//  MessagesExtension
//
//  Created by Naim Lujan on 8/3/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    
    static let GifFilename = "gifFile.gif"
    static let ImageFilename = "image.png"
    static let Timeout = 8.0
    
    struct Giphy {
        static let Url = "www.giphy.com"
        static let Key = "b9985075a85d4d828592ccb7ae6d78a5"
    }
    
    struct Emotion {
        static let Key = "bc7a77ee1a82452eab8ada4a837f5f70"
    }
    
    struct ErrorMessage {
        static let NetworkIssue = "Network issue, please check connection and try again"
        static let NoFaceDetected = "No face detected, please try again"
    }
    
    struct View {
        static let SelfieImageFill: CGFloat = 0.7
    }
}
