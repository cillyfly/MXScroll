//
//  ContainerWeb.swift
//  MXScroll_Example
//
//  Created by cc x on 2018/7/24.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import WebKit
import XXNibBridge
import EasyPeasy

class ContainerWeb: UIView,XXNibBridge {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var topView: TopView!
    @IBOutlet weak var bottomView: TopView!
  
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func loadModel(){
        topView.loadModel(str: "Use the switch context button in the upper left corner of this page to switch between your personal context (cillyfly) and organizations you are a member of.") 
        bottomView.loadModel(str: "After you switch contexts you’ll see an organization-focused dashboard that lists out organization repositories and activities.")
        
        let url = URL(string: "https://mp.weixin.qq.com/s/8Ja85jEN67V4iJ6MKiEsQA")!
        webView.load(URLRequest(url: url))
        webView.scrollView.isScrollEnabled = false
 
    }

}
