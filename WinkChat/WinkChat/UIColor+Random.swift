//
//  UIColor(.swift
//  MessagesExtension
//
//  Created by Naim Lujan on 8/2/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import UIKit


extension UIColor {
    
    func getRandom() -> UIColor {
        let colors = [UIColor(red:0.00, green:1.00, blue:0.60, alpha:1.0),
                      UIColor(red:0.00, green:0.80, blue:1.00, alpha:1.0),
                      UIColor(red:0.60, green:0.20, blue:1.00, alpha:1.0),
                      UIColor(red:1.00, green:0.40, blue:0.40, alpha:1.0),
                      UIColor(red:1.00, green:0.95, blue:0.36, alpha:1.0)]
        let index = Int(arc4random_uniform(UInt32(colors.count)))
        return colors[index]
    }
    
}
