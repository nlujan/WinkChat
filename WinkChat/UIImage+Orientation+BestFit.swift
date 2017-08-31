//
//  UIImageExtension.swift
//  WinkChat
//
//  Created by Naim Lujan on 6/25/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func imageWithAdjustedOrientation(deviceOrientation: UIInterfaceOrientation) -> UIImage {
        
        var imageOrientation : UIImageOrientation?
        
        switch (deviceOrientation) {
        case .portrait:
            imageOrientation = .right
            break
        case .landscapeRight:
            imageOrientation = .down
            break
        case .landscapeLeft:
            imageOrientation = .up
            break
        case .portraitUpsideDown:
            imageOrientation = .left
            break
        default:
            imageOrientation = .right
            break
        }
        return UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: imageOrientation!)
    }
    
    func getBestFitDimsWithin(container: UIView, scale: CGFloat) -> (width: CGFloat, height: CGFloat) {
        
        let aspectRatio: CGFloat = self.size.width / self.size.height
        
        var width = container.frame.width * scale
        var height = width * (1 / aspectRatio)
        
        if width > container.frame.width * scale || height > container.frame.height * scale  {
            height = container.frame.height * scale
            width = height * aspectRatio
        }
        
        return (width: width, height: height)
    }
}
