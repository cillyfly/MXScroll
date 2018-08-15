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
    @IBOutlet var viewheight: NSLayoutConstraint!
    @IBOutlet var webView: WKWebView!
    @IBOutlet var scrollview: UIScrollView!
    @IBOutlet var exampleView: UIView!
    @IBOutlet var uiwebview: UIWebView!
    @IBOutlet var containerWeb: ContainerWeb!
    override func viewDidLoad() {
        super.viewDidLoad()
        if webView != nil {
            loadWeb()
        } else if uiwebview != nil {
            loaduiwebview()
        } else if containerWeb != nil {
            containerWeb.loadModel()
        }
    }

    @IBAction func changeHeight(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        viewheight.constant = sender.isSelected ? 1000 : 10
    }

    @IBAction func ScrollToBottom(_ sender: Any) {
    }

    func loadWeb() {
        let url = URL(string: "https://mp.weixin.qq.com/s/8Ja85jEN67V4iJ6MKiEsQA")!
        webView.load(URLRequest(url: url))
        webView.scrollView.isScrollEnabled = false
    }

    func loaduiwebview() {
        let url = URL(string: "https://mp.weixin.qq.com/s/8Ja85jEN67V4iJ6MKiEsQA")!
        uiwebview.loadRequest(URLRequest(url: url))
        uiwebview.scrollView.isScrollEnabled = false
    }
}

extension HeaderViewController: MXViewControllerViewSource {
    func headerViewForMixObserveContentOffsetChange() -> UIView? {
        if webView != nil {
            return webView
        } else if scrollview != nil {
            return scrollview
        } else if uiwebview != nil {
            return uiwebview
        } else if containerWeb != nil {
            return containerWeb.webView
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
