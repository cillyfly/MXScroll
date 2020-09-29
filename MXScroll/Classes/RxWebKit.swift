//
//  RxWebKit.swift
//  WebViewHeight
//  解决webview的高度问题
//  Created by cc x on 2018/7/13.
//  Copyright © 2018 cillyfly. All rights reserved.
//

import EasyPeasy
import Foundation
import WebKit
#if !RX_NO_MODULE
  import RxCocoa
  import RxSwift
#endif

func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
  guard let returnValue = object as? T else {
    throw RxCocoaError.castingError(object: object, targetType: resultType)
  }
  return returnValue
}

extension Reactive where Base: UIWebView {
  // make the webview out frame same with content
  public var MatchHeightEqualToContent: Binder<CGFloat> {
    return Binder(base) { webview, value in
      webview.easy.layout(
        Height(value)
      )
    }
  }

  // export to public the real content height. insert js function when webview is did finish load
  public var realContentHeight: Observable<CGFloat> {
    return base.scrollView.rx.observeWeakly(CGSize.self, "contentSize")
      .map { $0?.height ?? 0 }.distinctUntilChanged()
  }
}

extension Reactive where Base: WKWebView {
  /// Reactive wrapper for delegate method `webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)`
  public var didFinishNavigation: ControlEvent<WKNavigationEvent> {
    let source: Observable<WKNavigationEvent> = delegate
      .methodInvoked(.didFinishNavigation)
      .map(navigationEventWith)
    return ControlEvent(events: source)
  }

  /// Reactive wrapper for `navigationDelegate`.
  public var delegate: DelegateProxy<WKWebView, WKNavigationDelegate> {
    return RxWKNavigationDelegateProxy.proxy(for: base)
  }

  private func navigationEventWith(_ arg: [Any]) throws -> WKNavigationEvent {
    let view = try castOrThrow(WKWebView.self, arg[0])
    let nav = try castOrThrow(WKNavigation.self, arg[1])
    return (view, nav)
  }

  // make the webview out frame same with content
  public var MatchHeightEqualToContent: Binder<CGFloat> {
    return Binder(base) { webview, value in
      webview.easy.layout(
        Height(value)
      )
    }
  }

  // export to public the real content height. insert js function when webview is did finish load
  public var realContentHeight: Observable<CGFloat> {
    return base.scrollView.rx.observeWeakly(CGSize.self, "contentSize")
      .map { $0?.height == 0 ? 500 : ($0?.height)! }
  }

  // use js function to get the final height
  private var getHeightFromJS: Observable<CGFloat> {
    return Observable.create({ (observer) -> Disposable in
      self.base.evaluateJavaScript("document.readyState", completionHandler: { complete, error in
        if complete != nil {
          self.base.evaluateJavaScript("document.body.scrollHeight", completionHandler: { height, error in
            if let e = error {
              observer.onError(e)
            } else {
              let h = height as! CGFloat
              observer.onNext(h)
            }
                    })
        }
        if let e = error {
          observer.onError(e)
        }
            })
      return Disposables.create()
        })
  }
}

extension Reactive where Base: WKWebView {
  /// WKWebView + WKNavigation
  public typealias WKNavigationEvent = (webView: WKWebView, navigation: WKNavigation)
}

private extension Selector {
  static let didFinishNavigation = #selector(WKNavigationDelegate.webView(_:didFinish:))
}

public typealias RxWKNavigationDelegate = DelegateProxy<WKWebView, WKNavigationDelegate>

open class RxWKNavigationDelegateProxy: RxWKNavigationDelegate, DelegateProxyType, WKNavigationDelegate {
  /// Type of parent object
  public private(set) weak var webView: WKWebView?

  /// Init with ParentObject
  public init(parentObject: ParentObject) {
    webView = parentObject
    super.init(parentObject: parentObject, delegateProxy: RxWKNavigationDelegateProxy.self)
  }

  /// Register self to known implementations
  public static func registerKnownImplementations() {
    register { parent -> RxWKNavigationDelegateProxy in
      RxWKNavigationDelegateProxy(parentObject: parent)
    }
  }

  /// Gets the current `WKNavigationDelegate` on `WKWebView`
  open class func currentDelegate(for object: ParentObject) -> WKNavigationDelegate? {
    return object.navigationDelegate
  }

  /// Set the navigationDelegate for `WKWebView`
  open class func setCurrentDelegate(_ delegate: WKNavigationDelegate?, to object: ParentObject) {
    object.navigationDelegate = delegate
  }
}
