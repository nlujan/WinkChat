//
//  ExpandedViewController.swift
//  WinkChat
//
//  Created by Naim Lujan on 4/11/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import UIKit

class ExpandedViewController: UIViewController {
    
    @IBOutlet var image: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        image.image = UIImage.gif(url: "https://media.giphy.com/media/26FPx9SsBUO4J1isE/giphy.gif")
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
