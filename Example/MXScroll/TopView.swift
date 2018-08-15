//
//  TopView.swift
//  MXScroll_Example
//
//  Created by cc x on 2018/7/25.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import XXNibBridge
class TopView: UIView,XXNibBridge {

    @IBOutlet weak var label: UILabel!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func loadModel(str:String){
        label.text = str
    }
}
