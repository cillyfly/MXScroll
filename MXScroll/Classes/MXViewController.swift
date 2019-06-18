//
//  MXViewController.swift
//  WebViewHeight
//
//  Created by cc x on 2018/7/17.
//  Copyright © 2018 cillyfly. All rights reserved.
//

import EasyPeasy
import UIKit

/**
 *  Public protocol of  MXViewController for content changes and makes the scroll effect.
 */
@objc public protocol MXViewControllerViewSource {
    ///  By default, MXScrollView will observe the default view of viewcontroller for content
    ///  changes and makes the scroll effect. If you want to change the default view, implement
    ///  MXViewControllerViewSource and pass your custom view.
    ///
    /// - Returns: observe view
    @objc optional func viewForMixToObserveContentOffsetChange() -> UIView
    
    /// By default MXScrollView will not observe the default view of HeaderViewController for content changes.
    /// if you want to change the headerview's content height implement MXViewControllerViewSource and pass your autochange heigth view.
    @objc optional func headerViewForMixObserveContentOffsetChange() -> UIView?
}

public class MXViewController<T: MXSegmentProtocol>: UIViewController where T: UIView {
    /// settting segment from outside
    open var segmentView: T!
    
     var segmentedScrollView = MXScrollView<T>(frame: CGRect.zero) 
    
    open var scrollView :UIScrollView{
        get{
            return segmentedScrollView
        }
    }
    /**
     *  Set ViewController for header view.
     */
    open var headerViewController: UIViewController? {
        didSet {
            setDefaultValuesToSegmentedScrollView()
        }
    }
    
    /**
     *  Array of ViewControllers for segments.
     */
    open var segmentControllers = [UIViewController]() {
        didSet {
            setDefaultValuesToSegmentedScrollView()
        }
    }
    
    /**
     *  Set headerview offset height.
     *
     *  By default the height is 0.0
     *
     *  segmentedViewController. headerViewOffsetHeight = 10.0
     */
    open var headerViewOffsetHeight: CGFloat = 0.0 {
        didSet {
            segmentedScrollView.headerViewOffsetHeight = headerViewOffsetHeight
        }
    }
    
    /**
     *  Set height for segment view.
     *
     *  By default the height is 40.0
     *
     *  segmentedViewController.segmentViewHeight = 60.0
     */
    open var segmentViewHeight: CGFloat = 40.0 {
        didSet {
            segmentedScrollView.segmentViewHeight = segmentViewHeight
        }
    }
    
    /**
     *  Set vertical scroll indicator.
     *
     *  By default true.
     *
     *  segmentedScrollView.showsVerticalScrollIndicator = false
     */
    open var showsVerticalScrollIndicator = true {
        didSet {
            segmentedScrollView.mxShowsVerticalScrollIndicator = showsVerticalScrollIndicator
        }
    }
    
    /**
     *  Set horizontal scroll indicator.
     *
     *  By default true.
     *
     *  segmentedScrollView.showsHorizontalScrollIndicator = false
     */
    open var showsHorizontalScrollIndicator = true {
        didSet {
            segmentedScrollView.mxShowsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        }
    }
    
    open var shouldScrollToBottomAtFirstTime: Bool = true {
        didSet {
            segmentedScrollView.shouldScrollToBottomAtFirstTime = shouldScrollToBottomAtFirstTime
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     Custom initializer for SJSegmentedViewController.
     
     - parameter headerViewController: A UIViewController
     - parameter segmentControllers:   Array of UIViewControllers for segments.
     
     */
    public convenience init(headerViewController: UIViewController?,
                            segmentControllers: [UIViewController]) {
        self.init(nibName: nil, bundle: nil)
        self.headerViewController = headerViewController
        self.segmentControllers = segmentControllers
        setDefaultValuesToSegmentedScrollView()
    }
    
    public convenience init(headerViewController: UIViewController?,
                            segmentControllers: [UIViewController],
                            segmentView: T?) {
        self.init(nibName: nil, bundle: nil)
        self.headerViewController = headerViewController
        self.segmentControllers = segmentControllers
        self.segmentView = segmentView
        setDefaultValuesToSegmentedScrollView()
    }
    
    /**
     * Set the default values for the segmented scroll view.
     */
    func setDefaultValuesToSegmentedScrollView() {
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldScrollToBottomAtFirstTime {
            scrollToBottom()
        }
    }
    
    public override func loadView() {
        super.loadView()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        setupSegmentScrollView()
        loadControllers()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
            print("viewDidLayoutSubviews")
        let topSpacing = MXUtil.getTopSpacing(self)
        segmentedScrollView.topSpacing = topSpacing
        segmentedScrollView.bottomSpacing = MXUtil.getBottomSpacing(self)
        segmentedScrollView.easy.layout(Top(topSpacing).to(view))
        segmentedScrollView.updateSubview(view.bounds)
    }
    
    func setupSegmentScrollView() {
        let topSpacing = MXUtil.getTopSpacing(self)
        segmentedScrollView.topSpacing = topSpacing
        
        let bottomSpacing = MXUtil.getBottomSpacing(self)
        segmentedScrollView.bottomSpacing = bottomSpacing
        view.addSubview(segmentedScrollView)
        
        segmentedScrollView.easy.layout(Left(0),
                                        Right(0),
                                        Top(topSpacing).to(view),
                                        Bottom(bottomSpacing))
        
        segmentedScrollView.setContainerView()
    }
    
    /**
     Method for adding the HeaderViewController into the container
     
     - parameter headerViewController: Header ViewController.
     */
    func addHeaderViewController(_ headerViewController: UIViewController) {
      addChild(headerViewController)
        segmentedScrollView.addHeaderView(view: headerViewController.view)
        if let delegate = headerViewController as? MXViewControllerViewSource, let v = delegate.headerViewForMixObserveContentOffsetChange?() {
            segmentedScrollView.setListenHeaderView(view: v)
            
        } else {
            headerViewController.view.layoutIfNeeded()
            segmentedScrollView.headerViewHeight = headerViewController.view.frame.height
            segmentedScrollView.updateHeaderHeight()
        }
        
      headerViewController.didMove(toParent: self)
    }
    
    /**
     Method for adding the array of content ViewControllers into the container
     
     - parameter contentControllers: array of ViewControllers
     */
    func addContentControllers(_ contentControllers: [UIViewController]) {
        for controller in contentControllers {
            addChild(controller)
            segmentedScrollView.addContentView(controller.view, frame: view.bounds)
            controller.didMove(toParent: self)
            if let delegate = controller as? MXViewControllerViewSource {
                let v = delegate.viewForMixToObserveContentOffsetChange!()
                segmentedScrollView.contentViews.append(v)
            } else {
                segmentedScrollView.contentViews.append(controller.view)
            }
        }
        segmentedScrollView.listenContentOffset()
        segmentedScrollView.addSegmentView(segmentView, frame: view.bounds)
    }
    
    /**
     * Method for loading content ViewControllers and header ViewController
     */
    func loadControllers() {
        if headerViewController == nil {
            headerViewController = UIViewController()
        }
        
        addHeaderViewController(headerViewController!)
        addContentControllers(segmentControllers)
    }
}

extension MXViewController {
    public func scrollToBottom() {
        segmentedScrollView.scrollToBottom(animated: false)
    }
}
