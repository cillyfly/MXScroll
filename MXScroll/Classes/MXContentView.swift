//
//  MXContentView.swift
//  WebViewHeight
//
//  Created by cc x on 2018/7/13.
//  Copyright © 2018 cillyfly. All rights reserved.
//

import EasyPeasy
import UIKit

class MXContentView: UIScrollView {
  var pageIndex = 0
  var contentViews = [UIView]()
  var contentView: UIView!

  var shouldNofi: Bool = false
  var indexChange: didIndexChange?

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    delegate = self
    isPagingEnabled = true

    contentView = UIView()
    contentView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(contentView)

    contentView.easy.layout(
      Edges(),
      Height().like(self)
    )
  }

  func addContentView(_ view: UIView, frame: CGRect) {
    contentView.addSubview(view)
    let w = Int(frame.size.width)
    if contentViews.count > 0 {
      let previewsView = contentViews.last
      view.easy.layout(
        Left(0).to(previewsView!, .right)
      )
    } else {
      view.easy.layout(
        Left(0)
      )
    }

    view.easy.layout(
      Top(0),
      Bottom(0),
      Width(CGFloat(w))
    )

    contentViews.append(view)
    let totalw = w * contentViews.count
    contentView.easy.layout(
      Width(CGFloat(totalw))
    )
  }

  func updateContentControllersFrame(_ frame: CGRect) {
    let width = frame.size.width
    let totalw = width * CGFloat(contentViews.count)
    contentView.easy.layout(
      Width(CGFloat(totalw))
    )

    for c in contentViews {
      c.easy.layout(
        Width(width)
      )
    }

    layoutIfNeeded()
    var point = contentOffset
    point.x = CGFloat(pageIndex) * width
    setContentOffset(point, animated: true)
  }

  func movePageToIndex(_ index: Int, animated: Bool) {
    pageIndex = index
    let point = CGPoint(x: index * Int(bounds.size.width), y: 0)

    if animated == true {
      UIView.animate(withDuration: 0.3) {
        self.contentOffset = point
      }
    } else {
      contentOffset = point
    }
  }
}

extension MXContentView: UIScrollViewDelegate {
  func scrollViewDidEndDecelerating(_: UIScrollView) {
    pageIndex = Int(contentOffset.x / bounds.size.width)
    indexChange?(pageIndex)
  }
}

extension MXContentView: MXSegmentProtocol {
  var change: MXContentView.didIndexChange {
    get {
      return indexChange!
    }
    set {
      indexChange = newValue
    }
  }

  func setSelected(index: Int, animator: Bool) {
    movePageToIndex(index, animated: animator)
  }
}
