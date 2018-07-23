//
//  MXExampleViewController.swift
//  MXScroll_Example
//
//  Created by cc x on 2018/7/20.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import MXScroll

class MXExampleViewController: UIViewController {

    var mx:MXViewController<MSSegmentControl>!
    @IBOutlet weak var containerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadVC()
    }

    func loadVC(){
        let header = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "HeaderViewController")
        
        let headerScroll = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "HeaderViewController2")
        
        let headerNormal = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "HeaderViewController3")
        
 
        
        let child1 = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ChildViewController")
        
        let child2 = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "SecondViewController")
        
        let segment = MSSegmentControl(sectionTitles: ["Comment", "Sports"])
        setupSegment(segmentView: segment)
        
         mx = MXViewController<MSSegmentControl>.init(headerViewController: headerScroll, segmentControllers: [child2,child1], segmentView: segment)
        mx.headerViewOffsetHeight = 10
        mx.view.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        mx.title = "MIX"
        mx.shouldScrollToBottomAtFirstTime = true
 
        
        
        addChildViewController(mx)
        containerView.addSubview(mx.view)
        mx.view.frame = containerView.bounds
        mx.didMove(toParentViewController: self)
        
     
    }
    @IBAction func toBottom(_ sender: Any) {
        if mx != nil {
            mx.scrollToBottom()
        }
    }
    
    
    
    func setupSegment(segmentView: MSSegmentControl) {
        segmentView.borderType = .none
        segmentView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 0, alpha: 1)
        segmentView.selectionIndicatorColor = #colorLiteral(red: 0.9759539962, green: 0.3313286304, blue: 0.008939011954, alpha: 1)
        segmentView.selectionIndicatorHeight = 2
        
        segmentView.selectedTitleTextAttributes = [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 0.9759539962, green: 0.3313286304, blue: 0.008939011954, alpha: 1), NSAttributedStringKey.font: Segment_statu_titleSelected]
        segmentView.titleTextAttributes = [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1), NSAttributedStringKey.font: Segment_statu_titleNormal]
        
        segmentView.segmentWidthStyle = .fixed
        
        segmentView.indicatorWidthPercent = 1
        segmentView.selectionStyle = .textWidth
    }

}
