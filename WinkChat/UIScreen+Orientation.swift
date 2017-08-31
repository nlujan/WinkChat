//
//  UIScreen+Orientation.swift
//  WinkChat
//
//  Created by Naim Lujan on 8/11/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation
import UIKit


extension UIScreen {
    
    var orientation: UIInterfaceOrientation {
        let point: CGPoint = coordinateSpace.convert(.zero, to: fixedCoordinateSpace)
        
        if point == .zero {
            return .portrait
        } else if point.x != 0 && point.y != 0 {
            return .portraitUpsideDown
        } else if point.x == 0 && point.y != 0 {
            return .landscapeLeft
        } else if point.x != 0 && point.y == 0 {
            return .landscapeRight
        } else {
            return .unknown
        }
    }
    
}
