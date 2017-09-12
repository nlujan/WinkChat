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
        static let Key = "PLACE GIPHY API KEY HERE"
    }
    
    struct Emotion {
        static let Key = "PLACE MICROSOFT EMOTION API KEY HERE"
    }
    
    struct ErrorMessage {
        static let NetworkIssue = "Network issue, please check connection and try again"
        static let NoFaceDetected = "No face detected, please try again"
    }
    
    struct View {
        static let SelfieImageFill: CGFloat = 0.7
    }
}
