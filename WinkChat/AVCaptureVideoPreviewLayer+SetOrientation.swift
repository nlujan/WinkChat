//
//  AVCaptureVideoPreviewLayer+.swift
//  WinkChat
//
//  Created by Naim Lujan on 8/18/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import UIKit
import AVFoundation

extension AVCaptureVideoPreviewLayer {
    
    func setOrientation(orientation: UIInterfaceOrientation) {
        if let connection = self.connection {
            
            if connection.isVideoOrientationSupported {
                
                switch (orientation) {
                case .portrait: connection.videoOrientation = .portrait
                    break
                case .landscapeRight: connection.videoOrientation = .landscapeRight
                    break
                case .landscapeLeft: connection.videoOrientation = .landscapeLeft
                    break
                case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
                    break
                default: connection.videoOrientation = .portrait
                    break
                }
            }
        }
    }
}




