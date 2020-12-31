//
//  RxViewKit.swift
//  WebViewHeight
//
//  Created by cc x on 2018/7/13.
//  Copyright © 2018 cillyfly. All rights reserved.
//

import UIKit
import EasyPeasy
#if !RX_NO_MODULE
import RxCocoa
import RxSwift
#endif

extension Reactive where Base == UIView {
     var MatchHeightEqualToContent:Binder<CGFloat>{
        return Binder(self.base){(scroll,value) in
            scroll.easy.layout(
                Height(value)
            )
        }
    }
    
    // export to public the real content height.
     var realContentHeight: Observable<CGFloat> {
        return self.observeWeakly(CGRect.self, "frame").map{$0?.height ?? 0} 
    }
    
 
}
