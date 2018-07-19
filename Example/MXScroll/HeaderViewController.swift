//
//  HeaderViewController.swift
//  WebViewHeight
//
//  Created by cc x on 2018/7/17.
//  Copyright © 2018 cillyfly. All rights reserved.
//

import MXScroll
import UIKit
import WebKit
class HeaderViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var viewheight: NSLayoutConstraint!
    @IBOutlet var webView: WKWebView!
    @IBOutlet var scrollview: UIScrollView!
    @IBOutlet weak var exampleView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if webView != nil {
            loadWeb()
        }
    }
    @IBAction func changeHeight(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        viewheight.constant = sender.isSelected ? 1000:10
    }
    
    func loadWeb() {
        let url = URL(string: "https://mp.weixin.qq.com/s?src=11&timestamp=1531997396&ver=1008&signature=yLWN4rHkjRXq8BuFxY5UuCWY3AREbDAGKNA1oc-nc4DiUWzFBdQA0RSdiqR73U-b-r2Qdjw4ousPipnZqtigHuoA36cjgNOfwHc1XhDtixaQgXtRVukjbdPHJZpSdYtd&new=1")!
        webView.load(URLRequest(url: url))
        webView.scrollView.isScrollEnabled = false
    }
}

extension HeaderViewController: MXViewControllerViewSource {
    func headerViewForContentOb() -> UIView? {
        if webView != nil {
            return webView
        }else if scrollview != nil { 
            return scrollview
        }
        return nil
    }
}

extension HeaderViewController {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("-------------------- start ------------------")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("------------------- finish -----------------")
    }
}
