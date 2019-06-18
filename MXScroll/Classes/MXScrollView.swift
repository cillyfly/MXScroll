//
//  MXScrollView.swift
//  WebViewHeight
//
//  Created by cc x on 2018/7/13.
//  Copyright © 2018 cillyfly. All rights reserved.
//

import EasyPeasy
import RxSwift
import UIKit
import WebKit

class MXScrollView<T: MXSegmentProtocol>: UIScrollView where T: UIView {
  let dispose = DisposeBag()

  var topSpacing: CGFloat = 0
  var bottomSpacing: CGFloat = 0

  //  HeaderView
  var headerView: UIView?
  var headerViewOffsetHeight: CGFloat?
  var headerViewHeight: CGFloat = 0.0

  //  Container layer
  var containerView: UIView!

  //  SegmentView
  var segmentView: T?
  var segmentViewHeight: CGFloat = 40

  //  ThirdPart
  var contentView: MXContentView!

  var contentViews = [UIView]()

  var shouldScrollToBottomAtFirstTime: Bool = false

  var mxShowsVerticalScrollIndicator: Bool = false {
    didSet {
      showsVerticalScrollIndicator = mxShowsVerticalScrollIndicator
      contentView?.showsVerticalScrollIndicator = mxShowsVerticalScrollIndicator
    }
  }

  var mxShowsHorizontalScrollIndicator: Bool = false {
    didSet {
      showsHorizontalScrollIndicator = mxShowsHorizontalScrollIndicator
      contentView?.showsHorizontalScrollIndicator = mxShowsHorizontalScrollIndicator
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    sizeToFit()
    translatesAutoresizingMaskIntoConstraints = false
    showsHorizontalScrollIndicator = mxShowsHorizontalScrollIndicator
    showsVerticalScrollIndicator = mxShowsVerticalScrollIndicator
    decelerationRate = UIScrollView.DecelerationRate.fast
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // setup containerview
  func setContainerView() {
    if containerView == nil {
      containerView = UIView()
      addSubview(containerView)
      containerView.easy.layout(
        Top(0),
        Right(0),
        Left(0),
        Width().like(self),
        Bottom(0).with(.medium),
        Height(getContentHeight())
      )
    }
  }

  func updateSubview(_ frame: CGRect) {
    containerView.easy.layout(Height(getContentHeight()))
    containerView.layoutIfNeeded()

    contentView.layoutIfNeeded()
    contentView.updateContentControllersFrame(frame)
  }

  // add header
  func addHeaderView(view: UIView) {
    if headerView == nil {
      headerView = view
      containerView.addSubview(headerView!)
      headerView?.easy.layout(
        Top(0),
        Right(0),
        Left(0),
        Height(0).with(.low),
        Bottom(0).with(.medium)
      )
    }
  }

  func setListenHeaderView(view: UIView) {
    bindViewHieghtWithRealHeight(view: view)
  }

  private func bindViewHieghtWithRealHeight(view: UIView) {
    if let web = view as? WKWebView {
      let realHeightOB = web.rx.realContentHeight.share()
      realHeightOB.bind(to: web.rx.MatchHeightEqualToContent).disposed(by: dispose)
      realHeightOB
        .subscribe { eve in
          if !eve.isStopEvent {
            self.updateHeaderHeight()
            if self.shouldScrollToBottomAtFirstTime {
              self.scrollToBottom(animated: false)
            }
          }
        }.disposed(by: dispose)

    } else if let uweb = view as? UIWebView {
      let realHeightOB = uweb.rx.realContentHeight.share()
      realHeightOB.bind(to: uweb.rx.MatchHeightEqualToContent).disposed(by: dispose)
      realHeightOB.observeOn(MainScheduler.asyncInstance)
        .subscribe { eve in
          if !eve.isStopEvent {
            self.updateHeaderHeight()
            if self.shouldScrollToBottomAtFirstTime {
              self.scrollToBottom(animated: false)
            }
          }
        }.disposed(by: dispose)
    } else if let scroll = view as? UIScrollView {
      scroll.rx.realContentHeight.bind(to: scroll.rx.MatchHeightEqualToContent).disposed(by: dispose)
      scroll.rx.realContentHeight.skipWhile { $0 == 0.0 }
        .delay(0.01, scheduler: MainScheduler.asyncInstance) 
        .subscribe { [unowned self] eve in
          if !eve.isStopEvent {
            self.updateHeaderHeight()
            if self.shouldScrollToBottomAtFirstTime {
              self.scrollToBottom(animated: false)
              self.shouldScrollToBottomAtFirstTime = false
            }
          }
        }.disposed(by: dispose)

    } else {
      view.rx.realContentHeight.bind(to: view.rx.MatchHeightEqualToContent).disposed(by: dispose)
      view.rx.realContentHeight.subscribe { [unowned self] eve in
        if !eve.isStopEvent {
          self.updateHeaderHeight()
        }
      }.disposed(by: dispose)
    }
  }

  func updateHeaderHeight() {
    headerView?.layoutIfNeeded()
    headerViewHeight = headerView?.frame.height ?? 0
    containerView.easy.layout(Height(getContentHeight()))
  }

  // add segment
  func addSegmentView(_ segment: T, frame: CGRect) {
    // only if  the contentView's count > 1 segment will show
    if contentViews.count > 1 {
      segmentView = segment
      segment.frame = CGRect(x: 0, y: 0, width: frame.width, height: segmentViewHeight)
      addSubview(segment)

      let view = headerView == nil ? containerView : headerView
      segment.easy.layout(
        Left(0),
        Right(0),
        Width().like(containerView),
        Height(segmentViewHeight),
        Top(headerViewOffsetHeight ?? 0).to(view!, .bottom)
      )
      segmentView!.change = { [unowned self] index in
        self.contentView.setSelected(index: index, animator: false)
      }
    } else {
      segmentViewHeight = 0
    }
  }

  //   Add the third View
  func createContentView() -> MXContentView {
    let contentView = MXContentView(frame: CGRect.zero)
    contentView.bounces = bounces
    containerView.addSubview(contentView)

    let topview = (headerView == nil ? containerView : headerView)
    contentView.easy.layout(
      Left(0),
      Right(0),
      Top(segmentViewHeight + (headerViewOffsetHeight ?? 0)).to(topview!, .bottom),
      Bottom(0).with(.medium)
    )
    return contentView
  }

  func addContentView(_ contentView: UIView, frame: CGRect) {
    if self.contentView == nil {
      self.contentView = createContentView()
      self.contentView.change = { [unowned self] index in
        self.segmentView?.setSelected(index: index, animator: true)
      }
    }
    self.contentView.addContentView(contentView, frame: frame)
  }
}

struct DiffNewOld {
  var diff: CGFloat = 0.0
  var old: CGPoint = CGPoint(x: 0, y: 0)
  var scrollview: UIScrollView!
}

extension MXScrollView {
  func listenContentOffset() {
    var shouldListen: Bool = true
    contentViews.forEach { view in
      if let scroll = view as? UIScrollView {
        let offsetob = Observable.zip(scroll.rx.contentOffset, scroll.rx.contentOffset.skip(1))
          .map { (old, new) -> DiffNewOld in
            let diff = old.y - new.y
            var model = DiffNewOld()
            model.diff = diff
            model.old = old
            model.scrollview = scroll
            return model
          }
          .filter { _ in shouldListen }
          .share()

        // up
        offsetob
          .observeOn(MainScheduler.asyncInstance)
          .filter { $0.diff > 0.0 }
          .subscribe { [unowned self] eve in
            guard self.headerViewHeight != 0.0, self.contentOffset.y != 0.0 else { return }
            guard let model = eve.element else { return }
            guard model.scrollview.contentOffset.y < 0.0 else { return }
            guard self.contentOffset.y > 0.0 else { return }

            if !eve.isStopEvent {
              var yPos = self.contentOffset.y - model.diff
              yPos = yPos < 0 ? 0 : yPos
              let newpos = CGPoint(x: self.contentOffset.x, y: yPos)
              shouldListen = false
              self.contentOffset = newpos
              model.scrollview.contentOffset = model.old
              shouldListen = true
            }
          }.disposed(by: dispose)

        // down
        offsetob
          .observeOn(MainScheduler.asyncInstance)
          .filter { $0.diff < 0.0 }
          .subscribe { [unowned self] eve in
            let offset = self.headerViewHeight
            guard self.contentOffset.y < offset else { return }
            guard let model = eve.element else { return }
            guard model.scrollview.contentOffset.y >= 0.0 else { return }

            if !eve.isStopEvent {
              var yPos = self.contentOffset.y - model.diff
              yPos = yPos > offset ? offset : yPos
              let updatedPos = CGPoint(x: self.contentOffset.x, y: yPos)
              shouldListen = false
              self.contentOffset = updatedPos
              model.scrollview.contentOffset = model.old
              shouldListen = true
            }
          }.disposed(by: dispose)
      }
    }
  }
}

extension MXScrollView {
  private func getContentHeight() -> CGFloat {
    guard superview != nil else {
      return 0
    }
    var contentHeight = (superview?.bounds.height)! + headerViewHeight
    contentHeight -= (topSpacing + bottomSpacing)
    return contentHeight
  }
}

extension MXScrollView {
  func scrollToBottom(animated: Bool) {
    layoutIfNeeded()
    let y = contentSize.height - bounds.size.height
    if contentOffset.y != y {
      let bottomOffset = CGPoint(x: 0, y: y)
      setContentOffset(bottomOffset, animated: animated)
    }
  }
}
