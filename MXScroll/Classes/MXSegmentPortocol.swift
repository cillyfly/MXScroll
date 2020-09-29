//
//  MXSegmentPortocol.swift
//  WebViewHeight
//
//  Created by cc x on 2018/7/13.
//  Copyright © 2018 cillyfly. All rights reserved.
//

import Foundation

@objc public protocol MXSegmentProtocol {
  typealias didIndexChange = (Int) -> Void
  // self change to tell other
  var change: didIndexChange { get set }
  // other change to tell self
  func setSelected(index: Int, animator: Bool)
}
