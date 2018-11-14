import Foundation
import UIKit

/// Selection Style for the Segmented control
///
/// - Parameter textWidth : Indicator width will only be as big as the text width
/// - Parameter fullWidth : Indicator width will fill the whole segment
/// - Parameter box : A rectangle that covers the whole segment
/// - Parameter arrow : An arrow in the middle of the segment pointing up or down depending
///                     on `SLSegmentedControlSelectionIndicatorLocation`
///
public enum MSSegmentedControlSelectionStyle:Int {
    case textWidth
    case fullWidth
    case box
    case arrow
}

public enum MSSegmentedControlSelectionIndicatorLocation:Int {
    case up
    case down
    case none // No selection indicator
}

public enum MSSegmentedControlSegmentWidthStyle:Int {
    case fixed // Segment width is fixed
    case dynamic // Segment width will only be as big as the text width (including inset)
}

public enum MSSegmentedControlBorderType:Int {
    case none // 0
    case top // (1 << 0)
    case left // (1 << 1)
    case bottom // (1 << 2)
    case right // (1 << 3)
}

public enum MSSegmentedControlType:Int {
    case text
    case images
    case textImages
    case textLeftImages
}

public enum MSSegmentedControlStart {
    // 从左边开始
    case left
    case middle
    // 从右边开始
    case right
}

public let SLSegmentedControlNoSegment = -1

public typealias IndexChangeBlock = (Int) -> Void
public typealias MSTitleFormatterBlock = ((_ segmentedControl: MSSegmentControl, _ title: String, _ index: Int, _ selected: Bool) -> NSAttributedString)

public class MSSegmentControl: UIControl {
    private var _didIndexChange: (Int) -> Void = { _ in }
    
    public var sectionTitles: [String]! {
        didSet {
            self.updateSegmentsRects()
            self.setNeedsLayout()
            self.setNeedsDisplay()
        }
    }
    public var sectionImages: [UIImage]! {
        didSet {
            self.updateSegmentsRects()
            self.setNeedsLayout()
            self.setNeedsDisplay()
        }
    }
    public var sectionSelectedImages: [UIImage]!
    
    /// 为了排序增加的block
    public var sameIndexTouchBlock: IndexChangeBlock?
    
    /// Provide a block to be executed when selected index is changed.
    /// Alternativly, you could use `addTarget:action:forControlEvents:`
    public var indexChangeBlock: IndexChangeBlock?
    
    /// Used to apply custom text styling to titles when set.
    /// When this block is set, no additional styling is applied to the `NSAttributedString` object
    /// returned from this block.
    public var titleFormatter: MSTitleFormatterBlock?
    
    /// Text attributes to apply to labels of the unselected segments
    public var titleTextAttributes: [NSAttributedString.Key: Any]?
    
    /// Text attributes to apply to selected item title text.
    /// Attributes not set in this dictionary are inherited from `titleTextAttributes`.
    public var selectedTitleTextAttributes: [NSAttributedString.Key: Any]?
    
    public var fixLast: Bool = false
    
    /// Segmented control background color.
    /// Default is `[UIColor whiteColor]`
    open dynamic override var backgroundColor: UIColor! {
        set {
            MSSegmentControl.appearance().backgroundColor = newValue
        }
        get {
            return MSSegmentControl.appearance().backgroundColor
        }
    }
    
    /// Color for the selection indicator stripe
    public var selectionIndicatorColor: UIColor = .black {
        didSet {
            self.selectionIndicator.backgroundColor = self.selectionIndicatorColor
            self.selectionIndicatorBoxColor = self.selectionIndicatorColor
        }
    }
    
    public lazy var selectionIndicator: UIView = {
        let selectionIndicator = UIView()
        selectionIndicator.backgroundColor = self.selectionIndicatorColor
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        return selectionIndicator
    }()
    
    /// Color for the selection indicator box
    /// Default is selectionIndicatorColor
    public var selectionIndicatorBoxColor: UIColor = .black
    
    /// Color for the vertical divider between segments.
    /// Default is `[UIColor blackColor]`
    public var verticalDividerColor = UIColor.black
    
    // TODO: Add other visual apperance properities
    
    /// Specifies the style of the control
    /// Default is `text`
    public var type: MSSegmentedControlType = .text
    
    /// Specifies the style of the selection indicator.
    /// Default is `textWidth`
    public var selectionStyle: MSSegmentedControlSelectionStyle = .textWidth
    
    /// Specifies the style of the segment's width.
    /// Default is `fixed`
    public var segmentWidthStyle: MSSegmentedControlSegmentWidthStyle = .dynamic {
        didSet {
            if self.segmentWidthStyle == .dynamic && self.type == .images {
                self.segmentWidthStyle = .fixed
            }
        }
    }
    
    /// segment开始的顺序，可以从左边开始，也可以从右边开始
    public var segmentStart: MSSegmentedControlStart = .left
    
    /// Specifies the location of the selection indicator.
    /// Default is `up`
    public var selectionIndicatorLocation: MSSegmentedControlSelectionIndicatorLocation = .down {
        didSet {
            if self.selectionIndicatorLocation == .none {
                self.selectionIndicatorHeight = 0.0
            }
        }
    }
    
    /// Specifies the border type.
    /// Default is `none`
    public var borderType: MSSegmentedControlBorderType = .none {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /// Specifies the border color.
    /// Default is `black`
    public var borderColor = UIColor.black
    
    /// Specifies the border width.
    /// Default is `1.0f`
    public var borderWidthSG: CGFloat = 1.0
    
    /// Default is NO. Set to YES to show a vertical divider between the segments.
    public var verticalDividerEnabled = false
    
    /// Index of the currently selected segment.
    public var selectedSegmentIndex: Int = 0
    
    /// Height of the selection indicator stripe.
    public var selectionIndicatorHeight: CGFloat = 5.0
    
    public var edgeInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    public var selectionEdgeInset = UIEdgeInsets.zero
    public var verticalDividerWidth = 1.0
    public var selectionIndicatorBoxOpacity: Float = 0.3
    
    /// MARK: Private variable
    internal var selectionIndicatorStripLayer = CALayer()
    internal var selectionIndicatorBoxLayer = CALayer() {
        didSet {
            self.selectionIndicatorBoxLayer.opacity = self.selectionIndicatorBoxOpacity
            self.selectionIndicatorBoxLayer.borderWidth = self.borderWidthSG
        }
    }
    internal var selectionIndicatorArrowLayer = CALayer()
    internal var segmentWidth: CGFloat = 0.0
    internal var segmentWidthsArray: [CGFloat] = []
    internal var scrollView: MSScrollView! = {
        let scroll = MSScrollView()
        scroll.scrollsToTop = false
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    
    var badgeIndexSet: Set<Int> = Set()
    public var titles: [String] = []
    
    // MARK: - Init Methods
    
    /// Initialiaze the segmented control with only titles.
    ///
    /// - Parameter sectionTitles: array of strings for the section title
    public convenience init(sectionTitles titles: [String]) {
        self.init()
        self.setup()
        self.sectionTitles = titles
        self.type = .text
        self.postInitMethod()
    }
    
    /// Initialiaze the segmented control with only images/icons.
    ///
    /// - Parameter sectionImages: array of images for the section images.
    /// - Parameter selectedImages: array of images for the selected section images.
    public convenience init(sectionImages images: [UIImage], selectedImages sImages: [UIImage]) {
        self.init()
        self.setup()
        self.sectionImages = images
        self.sectionSelectedImages = sImages
        self.type = .images
        self.segmentWidthStyle = .fixed
        self.postInitMethod()
    }
    
    /// Initialiaze the segmented control with both titles and images/icons.
    ///
    /// - Parameter sectionTitles: array of strings for the section title
    /// - Parameter sectionImages: array of images for the section images.
    /// - Parameter selectedImages: array of images for the selected section images.
    public convenience init(sectionTitles titles: [String],
                            sectionImages images: [UIImage],
                            selectedImages sImages: [UIImage]) {
        self.init()
        self.setup()
        self.sectionTitles = titles
        self.sectionImages = images
        self.sectionSelectedImages = sImages
        self.type = .textImages
        
        assert(self.sectionTitles.count == self.sectionSelectedImages.count, "Titles and images are not in correct count")
        self.postInitMethod()
    }
    
    open override func awakeFromNib() {
        self.setup()
        self.postInitMethod()
    }
    
    private func setup() {
        self.addSubview(self.scrollView)
        self.backgroundColor = UIColor.lightGray
        self.isOpaque = false
        self.contentMode = .redraw
    }
    
    open func postInitMethod() {
    }
    
    // MARK: - View LifeCycle
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            // Control is being removed
            return
        }
        if self.sectionTitles != nil || self.sectionImages != nil {
            self.updateSegmentsRects()
        }
    }
    
    // MARK: - Drawing
    
    private func measureTitleAtIndex(index: Int) -> CGSize {
        if index >= self.sectionTitles.count {
            return CGSize.zero
        }
        let title = self.sectionTitles[index]
     
        let selected = (index == self.selectedSegmentIndex)
        var size = CGSize.zero
        if self.titleFormatter == nil {
            size = (title as NSString).size(withAttributes: selected ?
                self.finalSelectedTitleAttributes() : self.finalTitleAttributes())
        } else {
            size = self.titleFormatter!(self, title, index, selected).size()
        } 
        return size
    }
    
    private func attributedTitleAtIndex(index: Int) -> NSAttributedString {
        let title = self.sectionTitles[index]
        let selected = (index == self.selectedSegmentIndex)
        var str = NSAttributedString()
        if self.titleFormatter == nil {
            let attr = selected ? self.finalSelectedTitleAttributes() : self.finalTitleAttributes()
            str = NSAttributedString(string: title, attributes: attr)
        } else {
            str = self.titleFormatter!(self, title, index, selected)
        }
        return str
    }
    
    open override func draw(_ rect: CGRect) {
        self.backgroundColor.setFill()
        UIRectFill(self.bounds)
        
        self.selectionIndicatorArrowLayer.backgroundColor = self.selectionIndicatorColor.cgColor
        self.selectionIndicatorStripLayer.backgroundColor = self.selectionIndicatorColor.cgColor
        self.selectionIndicatorBoxLayer.backgroundColor = self.selectionIndicatorBoxColor.cgColor
        self.selectionIndicatorBoxLayer.borderColor = self.selectionIndicatorBoxColor.cgColor
        
        // Remove all sublayers to avoid drawing images over existing ones
        self.scrollView.layer.sublayers = nil
        
        let oldrect = rect
        if self.type == .text {
            self.editWithText(oldrect: oldrect)
        } else if self.type == .images {
            self.editWithImage(oldrect: oldrect)
        } else if self.type == .textImages {
            self.editWithTextImage(oldrect: oldrect)
        } else if self.type == .textLeftImages {
            self.editWithTextLeftImage(oldrect: oldrect)
        }
        
        if self.sectionTitles == nil {
            return
        }
        // Add the selection indicators
        if self.selectedSegmentIndex != SLSegmentedControlNoSegment {
            if self.selectionStyle == .arrow {
                if self.selectionIndicatorArrowLayer.superlayer == nil {
                    self.setArrowFrame()
                    self.scrollView.layer.addSublayer(self.selectionIndicatorArrowLayer)
                }
            } else {
                if self.selectionIndicatorStripLayer.superlayer == nil {
                    self.selectionIndicatorStripLayer.frame = self.frameForSelectionIndicator()
                    self.scrollView.layer.addSublayer(self.selectionIndicatorStripLayer)
                    
                    if self.selectionStyle == .box && self.selectionIndicatorBoxLayer.superlayer == nil {
                        self.selectionIndicatorBoxLayer.frame = self.frameForFillerSelectionIndicator()
                        self.selectionIndicatorBoxLayer.opacity = self.selectionIndicatorBoxOpacity
                        self.scrollView.layer.insertSublayer(self.selectionIndicatorBoxLayer, at: 0)
                    }
                }
            }
        }
    }
    
    func editWithText(oldrect: CGRect) {
        if self.sectionTitles == nil {
            return
        }
        for (index, _) in self.sectionTitles.enumerated() {
            let size = self.measureTitleAtIndex(index: index)
            let strWidth = size.width
            let strHeight = size.height
            var rectDiv = CGRect.zero
            var fullRect = CGRect.zero
            
            // Text inside the CATextLayer will appear blurry unless the rect values are rounded
            let isLocationUp: CGFloat = (self.selectionIndicatorLocation != .up) ? 0.0 : 1.0
            let isBoxStyle: CGFloat = (self.selectionStyle != .box) ? 0.0 : 1.0
            
            let a: CGFloat = (self.frame.height - (isBoxStyle * self.selectionIndicatorHeight)) / 2
            let b: CGFloat = (strHeight / 2) + (self.selectionIndicatorHeight * isLocationUp)
            let yPosition: CGFloat = CGFloat(roundf(Float(a - b)))
            
            var newRect = CGRect.zero
            if self.segmentWidthStyle == .fixed {
                let xPosition: CGFloat = CGFloat((self.segmentWidth * CGFloat(index)) + (self.segmentWidth - strWidth) / 2)
                newRect = CGRect(x: xPosition,
                                 y: yPosition,
                                 width: strWidth,
                                 height: strHeight)
                rectDiv = self.calculateRectDiv(at: index, xoffSet: nil)
                fullRect = CGRect(x: self.segmentWidth * CGFloat(index), y: 0.0, width: self.segmentWidth, height: oldrect.size.height)
            } else {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                var xOffset: CGFloat = 0.0
                var i = 0
                for width in self.segmentWidthsArray {
                    if index == i {
                        break
                    }
                    xOffset += width
                    i += 1
                }
                
                let widthForIndex = self.segmentWidthsArray[index]
                
                newRect = CGRect(x: xOffset, y: yPosition, width: widthForIndex, height: strHeight)
                
                fullRect = CGRect(x: self.segmentWidth * CGFloat(index), y: 0.0, width: widthForIndex, height: oldrect.size.height)
                rectDiv = self.calculateRectDiv(at: index, xoffSet: xOffset)
            }
            
            if self.fixLast && index == self.sectionTitles.count - 1 {
                newRect = CGRect(x: self.frame.width - ceil(newRect.size.width), y: ceil(newRect.origin.y), width: ceil(newRect.size.width), height: ceil(newRect.size.height))
                
            } else {
                // Fix rect position/size to avoid blurry labels
                newRect = CGRect(x: ceil(newRect.origin.x), y: ceil(newRect.origin.y), width: ceil(newRect.size.width), height: ceil(newRect.size.height))
            }
            
            let titleLayer = CATextLayer()
            titleLayer.frame = newRect
//            titleLayer.alignmentMode = .center
            titleLayer.alignmentMode = CATextLayerAlignmentMode.center
            if (UIDevice.current.systemVersion as NSString).floatValue < 10.0 {
//                titleLayer.truncationMode = .end
                titleLayer.truncationMode = CATextLayerTruncationMode.end
            }
            titleLayer.string = self.attributedTitleAtIndex(index: index)
            titleLayer.contentsScale = UIScreen.main.scale 
            self.scrollView.layer.addSublayer(titleLayer)
            
            // Vertical Divider
            self.addVerticalLayer(at: index, rectDiv: rectDiv)
            
            self.addBgAndBorderLayer(with: fullRect)
        }
    }
    
    func editWithImage(oldrect: CGRect) {
        if self.sectionImages == nil {
            return
        }
        for (index, image) in self.sectionImages.enumerated() {
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            
            let a = (self.frame.height - self.selectionIndicatorHeight) / 2
            let b = (imageHeight / 2) + (self.selectionIndicatorLocation == .up ? self.selectionIndicatorHeight : 0.0)
            let y: CGFloat = CGFloat(roundf(Float(a - b)))
            let x: CGFloat = (self.segmentWidth * CGFloat(index)) + (self.segmentWidth - imageWidth) / 2.0
            let newRect = CGRect(x: x, y: y, width: imageWidth, height: imageHeight)
            
            let imageLayer = CALayer()
            imageLayer.frame = newRect
            imageLayer.contents = image.cgImage
            
            if self.selectedSegmentIndex == index && self.sectionSelectedImages.count > index {
                let highlightedImage = self.sectionSelectedImages[index]
                imageLayer.contents = highlightedImage.cgImage
            }
            
            self.scrollView.layer.addSublayer(imageLayer)
            
            // vertical Divider
            self.addVerticalLayer(at: index, rectDiv: self.calculateRectDiv(at: index, xoffSet: nil))
            
            self.addBgAndBorderLayer(with: newRect)
        }
    }
    
    func editWithTextImage(oldrect: CGRect) {
        if self.sectionImages == nil {
            return
        }
        for (index, image) in self.sectionImages.enumerated() {
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            
            let stringHeight = self.measureTitleAtIndex(index: index).height
            let yOffset: CGFloat = CGFloat(roundf(Float(((self.frame.height - self.selectionIndicatorHeight) / 2) - (stringHeight / 2))))
            
            var imagexOffset: CGFloat = self.edgeInset.left
            var textxOffset: CGFloat = self.edgeInset.left
            
            var textWidth: CGFloat = 0.0
            if self.segmentWidthStyle == .fixed {
                imagexOffset = (self.segmentWidth * CGFloat(index)) + (self.segmentWidth / 2) - (imageWidth / 2.0)
                textxOffset = self.segmentWidth * CGFloat(index)
                textWidth = self.segmentWidth
            } else {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                let a = self.getDynamicWidthTillSegmentIndex(index: index)
                imagexOffset = a.0 + (a.1 / 2) - (imageWidth / 2)
                textxOffset = a.0
                textWidth = self.segmentWidthsArray[index]
            }
            
            let imageyOffset: CGFloat = CGFloat(roundf(Float(((self.frame.height - self.selectionIndicatorHeight) / 2) + 8.0)))
            
            let imageRect = CGRect(x: imagexOffset, y: imageyOffset, width: imageWidth, height: imageHeight)
            var textRect = CGRect(x: textxOffset, y: yOffset, width: textWidth, height: stringHeight)
            
            // Fix rect position/size to avoid blurry labels
            textRect = CGRect(x: ceil(textRect.origin.x), y: ceil(textRect.origin.y), width: ceil(textRect.size.width), height: ceil(textRect.size.height))
            
            let titleLayer = CATextLayer()
            titleLayer.frame = textRect
//            titleLayer.alignmentMode = .center
            titleLayer.alignmentMode = CATextLayerAlignmentMode.center
            if (UIDevice.current.systemVersion as NSString).floatValue < 10.0 {
//                titleLayer.truncationMode = .end
                titleLayer.truncationMode = CATextLayerTruncationMode.end
            }
            titleLayer.string = self.attributedTitleAtIndex(index: index)
            titleLayer.contentsScale = UIScreen.main.scale
            
            let imageLayer = CALayer()
            imageLayer.frame = imageRect
            imageLayer.contents = image.cgImage
            if self.selectedSegmentIndex == index && self.sectionSelectedImages.count > index {
                let highlightedImage = self.sectionSelectedImages[index]
                imageLayer.contents = highlightedImage.cgImage
            }
            
            self.scrollView.layer.addSublayer(imageLayer)
            self.scrollView.layer.addSublayer(titleLayer)
            
            self.addBgAndBorderLayer(with: imageRect)
        }
    }
    
    func editWithTextLeftImage(oldrect: CGRect) {
        if self.sectionTitles == nil {
            return
        }
        for (index, _) in self.sectionTitles.enumerated() {
            let size = self.measureTitleAtIndex(index: index)
            let strWidth = size.width
            let strHeight = size.height
            var rectDiv = CGRect.zero
            var fullRect = CGRect.zero
            
            // Text inside the CATextLayer will appear blurry unless the rect values are rounded
            let isLocationUp: CGFloat = (self.selectionIndicatorLocation != .up) ? 0.0 : 1.0
            let isBoxStyle: CGFloat = (self.selectionStyle != .box) ? 0.0 : 1.0
            
            let a: CGFloat = (self.frame.height - (isBoxStyle * self.selectionIndicatorHeight)) / 2
            let b: CGFloat = (strHeight / 2) + (self.selectionIndicatorHeight * isLocationUp)
            let yPosition: CGFloat = CGFloat(roundf(Float(a - b)))
            
            var newRect = CGRect.zero
            if self.segmentWidthStyle == .fixed {
                let xPosition: CGFloat = CGFloat((self.segmentWidth * CGFloat(index)) + (self.segmentWidth - strWidth) / 2)
                newRect = CGRect(x: xPosition,
                                 y: yPosition,
                                 width: strWidth,
                                 height: strHeight)
                rectDiv = self.calculateRectDiv(at: index, xoffSet: nil)
                fullRect = CGRect(x: self.segmentWidth * CGFloat(index), y: 0.0, width: self.segmentWidth, height: oldrect.size.height)
            } else {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                var xOffset: CGFloat = 0.0
                var i = 0
                for width in self.segmentWidthsArray {
                    if index == i {
                        break
                    }
                    xOffset += width
                    i += 1
                }
                
                let widthForIndex = self.segmentWidthsArray[index]
                
                newRect = CGRect(x: xOffset, y: yPosition, width: widthForIndex, height: strHeight)
                
                fullRect = CGRect(x: self.segmentWidth * CGFloat(index), y: 0.0, width: widthForIndex, height: oldrect.size.height)
                rectDiv = self.calculateRectDiv(at: index, xoffSet: xOffset)
            }
            // Fix rect position/size to avoid blurry labels
            newRect = CGRect(x: ceil(newRect.origin.x), y: ceil(newRect.origin.y), width: ceil(newRect.size.width), height: ceil(newRect.size.height))
            
            let titleLabel = UILabel()
            titleLabel.frame = newRect
            titleLabel.textAlignment = .left
            titleLabel.attributedText = self.attributedTitleAtIndex(index: index)
            self.scrollView.addSubview(titleLabel)
            
            // Vertical Divider
            self.addVerticalLayer(at: index, rectDiv: rectDiv)
            
            self.addBgAndBorderLayer(with: fullRect)
        }
    }
    private func calculateRectDiv(at index: Int, xoffSet: CGFloat?) -> CGRect {
        var a: CGFloat
        if xoffSet != nil {
            a = xoffSet!
        } else {
            a = self.segmentWidth * CGFloat(index)
        }
        let xPosition = CGFloat(a - CGFloat(self.verticalDividerWidth / 2))
        let rectDiv = CGRect(x: xPosition,
                             y: self.selectionIndicatorHeight * 2,
                             width: CGFloat(self.verticalDividerWidth),
                             height: self.frame.size.height - (self.selectionIndicatorHeight * 4))
        return rectDiv
    }
    
    // Add Vertical Divider Layer
    private func addVerticalLayer(at index: Int, rectDiv: CGRect) {
        if self.verticalDividerEnabled && index > 0 {
            let vDivLayer = CALayer()
            vDivLayer.frame = rectDiv
            vDivLayer.backgroundColor = self.verticalDividerColor.cgColor
            self.scrollView.layer.addSublayer(vDivLayer)
        }
    }
    
    private func addBgAndBorderLayer(with rect: CGRect) {
        // Background layer
        let bgLayer = CALayer()
        bgLayer.frame = rect
        self.layer.insertSublayer(bgLayer, at: 0)
        
        // Border layer
        if self.borderType != .none {
            let borderLayer = CALayer()
            borderLayer.backgroundColor = self.borderColor.cgColor
            var borderRect = CGRect.zero
            switch self.borderType {
            case .top:
                borderRect = CGRect(x: 0, y: 0, width: rect.size.width, height: self.borderWidthSG)
                break
            case .left:
                borderRect = CGRect(x: 0, y: 0, width: self.borderWidthSG, height: rect.size.height)
                break
            case .bottom:
                borderRect = CGRect(x: 0, y: rect.size.height, width: rect.size.width, height: self.borderWidthSG)
                break
            case .right:
                borderRect = CGRect(x: 0, y: rect.size.width, width: self.borderWidthSG, height: rect.size.height)
                break
            case .none:
                break
            }
            borderLayer.frame = borderRect
            bgLayer.addSublayer(borderLayer)
        }
    }
    
    private func setArrowFrame() {
        self.selectionIndicatorArrowLayer.frame = self.frameForSelectionIndicator()
        self.selectionIndicatorArrowLayer.mask = nil
        
        let arrowPath = UIBezierPath()
        var p1 = CGPoint.zero
        var p2 = CGPoint.zero
        var p3 = CGPoint.zero
        
        if self.selectionIndicatorLocation == .down {
            p1 = CGPoint(x: self.selectionIndicatorArrowLayer.bounds.size.width / 2, y: 0)
            p2 = CGPoint(x: 0, y: self.selectionIndicatorArrowLayer.bounds.size.height)
            p3 = CGPoint(x: self.selectionIndicatorArrowLayer.bounds.size.width, y: self.selectionIndicatorArrowLayer.bounds.size.height)
        } else if self.selectionIndicatorLocation == .up {
            p1 = CGPoint(x: self.selectionIndicatorArrowLayer.bounds.size.width / 2, y: self.selectionIndicatorArrowLayer.bounds.size.height)
            p2 = CGPoint(x: self.selectionIndicatorArrowLayer.bounds.size.width, y: 0)
        }
        arrowPath.move(to: p1)
        arrowPath.addLine(to: p2)
        arrowPath.addLine(to: p3)
        arrowPath.close()
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.selectionIndicatorArrowLayer.bounds
        maskLayer.path = arrowPath.cgPath
        self.selectionIndicatorArrowLayer.mask = maskLayer
    }
    
    /// Stripe width in range(0.0 - 1.0).
    /// Default is 1.0
    public var indicatorWidthPercent: Double = 1.0 {
        didSet {
            if !(indicatorWidthPercent <= 1.0 && indicatorWidthPercent >= 0.0) {
                indicatorWidthPercent = max(0.0, min(indicatorWidthPercent, 1.0))
            }
        }
    }
    
    private func frameForSelectionIndicator() -> CGRect {
        var indicatorYOffset: CGFloat = 0
        if self.selectionIndicatorLocation == .down {
            indicatorYOffset = self.bounds.size.height - self.selectionIndicatorHeight + self.edgeInset.bottom
        } else if self.selectionIndicatorLocation == .up {
            indicatorYOffset = self.edgeInset.top
        }
        var sectionWidth: CGFloat = 0.0
        if self.type == .text {
            sectionWidth = self.measureTitleAtIndex(index: self.selectedSegmentIndex).width
        } else if self.type == .images {
            sectionWidth = self.sectionImages[self.selectedSegmentIndex].size.width
        } else if self.type == .textImages {
            let stringWidth = self.measureTitleAtIndex(index: self.selectedSegmentIndex).width
            let imageWidth = self.sectionImages[self.selectedSegmentIndex].size.width
            sectionWidth = max(stringWidth, imageWidth)
        }
        
        var indicatorFrame = CGRect.zero
        
        if self.selectionStyle == .arrow {
            var widthToStartOfSelIndex: CGFloat = 0.0
            var widthToEndOfSelIndex: CGFloat = 0.0
            if self.segmentWidthStyle == .dynamic {
                let a = self.getDynamicWidthTillSegmentIndex(index: self.selectedSegmentIndex)
                widthToStartOfSelIndex = a.0
                widthToEndOfSelIndex = widthToStartOfSelIndex + a.1
            } else {
                widthToStartOfSelIndex = CGFloat(self.selectedSegmentIndex) * self.segmentWidth
                widthToEndOfSelIndex = widthToStartOfSelIndex + self.segmentWidth
            }
            let xPos = widthToStartOfSelIndex + ((widthToEndOfSelIndex - widthToStartOfSelIndex) / 2) - (self.selectionIndicatorHeight)
            indicatorFrame = CGRect(x: xPos, y: indicatorYOffset, width: self.selectionIndicatorHeight * 2, height: self.selectionIndicatorHeight)
        } else {
            if self.selectionStyle == .textWidth && sectionWidth <= self.segmentWidth &&
                self.segmentWidthStyle != .dynamic {
                let widthToStartOfSelIndex: CGFloat = CGFloat(self.selectedSegmentIndex) * self.segmentWidth
                let widthToEndOfSelIndex: CGFloat = widthToStartOfSelIndex + self.segmentWidth
                
                var xPos = (widthToStartOfSelIndex - (sectionWidth / 2)) + ((widthToEndOfSelIndex - widthToStartOfSelIndex) / 2)
                xPos += self.edgeInset.left
                indicatorFrame = CGRect(x: xPos, y: indicatorYOffset, width: (sectionWidth - self.edgeInset.right), height: self.selectionIndicatorHeight)
            } else {
                if self.segmentWidthStyle == .dynamic {
                    var selectedSegmentOffset: CGFloat = 0
                    var i = 0
                    for width in self.segmentWidthsArray {
                        if self.selectedSegmentIndex == i {
                            break
                        }
                        selectedSegmentOffset += width
                        i += 1
                    }
                    guard self.segmentWidthsArray.count > self.selectedSegmentIndex else { return indicatorFrame }
                    indicatorFrame = CGRect(x: selectedSegmentOffset + self.edgeInset.left,
                                            y: indicatorYOffset,
                                            width: self.segmentWidthsArray[self.selectedSegmentIndex] - self.edgeInset.right - self.edgeInset.left,
                                            height: self.selectionIndicatorHeight + self.edgeInset.bottom)
                    if self.fixLast && self.segmentWidthsArray.count == self.selectedSegmentIndex + 1 {
                        indicatorFrame.changeXTo(frame.size.width - self.segmentWidthsArray[self.selectedSegmentIndex] + self.edgeInset.right)
                    }
                } else {
                    let xPos = (self.segmentWidth * CGFloat(self.selectedSegmentIndex)) + self.edgeInset.left
                    indicatorFrame = CGRect(x: xPos, y: indicatorYOffset, width: (self.segmentWidth - self.edgeInset.right - self.edgeInset.left), height: self.selectionIndicatorHeight)
                }
            }
        }
        
        if self.selectionStyle != .arrow {
            let currentIndicatorWidth = indicatorFrame.size.width
            let widthToMinus = CGFloat(1 - self.indicatorWidthPercent) * currentIndicatorWidth
            // final width
            indicatorFrame.size.width = currentIndicatorWidth - widthToMinus
            // frame position
            indicatorFrame.origin.x += widthToMinus / 2
        }
        
        return indicatorFrame
    }
    
    private func getDynamicWidthTillSegmentIndex(index: Int) -> (CGFloat, CGFloat) {
        var selectedSegmentOffset: CGFloat = 0
        var i = 0
        var selectedSegmentWidth: CGFloat = 0
        for width in self.segmentWidthsArray {
            if index == i {
                selectedSegmentWidth = width
                break
            }
            selectedSegmentOffset += width
            i += 1
        }
        return (selectedSegmentOffset, selectedSegmentWidth)
    }
    
    private func frameForFillerSelectionIndicator() -> CGRect {
        if self.segmentWidthStyle == .dynamic {
            var selectedSegmentOffset: CGFloat = 0
            var i = 0
            for width in self.segmentWidthsArray {
                if self.selectedSegmentIndex == i {
                    break
                }
                selectedSegmentOffset += width
                i += 1
            }
            
            return CGRect(x: selectedSegmentOffset, y: 0, width: self.segmentWidthsArray[self.selectedSegmentIndex], height: self.frame.height)
        }
        return CGRect(x: self.segmentWidth * CGFloat(self.selectedSegmentIndex), y: 0, width: self.segmentWidth, height: self.frame.height)
    }
    
    private func updateSegmentsRects() {
        self.scrollView.contentInset = UIEdgeInsets.zero
        self.layoutIfNeeded()
        self.scrollView.frame = CGRect(origin: CGPoint.zero, size: self.frame.size)
        
        let count = self.sectionCount()
        if count > 0 {
            self.segmentWidth = self.frame.size.width / CGFloat(count)
        }
        
        if self.type == .text {
            if self.segmentWidthStyle == .fixed {
                for (index, _) in self.sectionTitles.enumerated() {
                    let stringWidth = self.measureTitleAtIndex(index: index).width +
                        self.edgeInset.left + self.edgeInset.right
                    self.segmentWidth = max(stringWidth, self.segmentWidth)
                }
            } else if self.segmentWidthStyle == .dynamic {
                var arr = [CGFloat]()
                for (index, _) in self.sectionTitles.enumerated() {
                    let stringWidth = self.measureTitleAtIndex(index: index).width +
                        self.edgeInset.left + self.edgeInset.right
                    arr.append(stringWidth)
                }
                self.segmentWidthsArray = arr
            }
        } else if self.type == .images {
            for image in self.sectionImages {
                let imageWidth = image.size.width + self.edgeInset.left + self.edgeInset.right
                self.segmentWidth = max(imageWidth, self.segmentWidth)
            }
        } else if self.type == .textImages {
            if self.segmentWidthStyle == .fixed {
                for (index, _) in self.sectionTitles.enumerated() {
                    let stringWidth = self.measureTitleAtIndex(index: index).width +
                        self.edgeInset.left + self.edgeInset.right
                    self.segmentWidth = max(stringWidth, self.segmentWidth)
                }
            } else if self.segmentWidthStyle == .dynamic {
                var arr = [CGFloat]()
                for (index, _) in self.sectionTitles.enumerated() {
                    let stringWidth = self.measureTitleAtIndex(index: index).width +
                        self.edgeInset.right
                    let imageWidth = self.sectionImages[index].size.width + self.edgeInset.left
                    arr.append(max(stringWidth, imageWidth))
                }
                self.segmentWidthsArray = arr
            }
        }
        self.scrollView.isScrollEnabled = true
        self.scrollView.contentSize = CGSize(width: self.totalSegmentedControlWidth(), height: self.frame.height)
    }
    
    private func sectionCount() -> Int {
        if self.type == .text || self.type == .textLeftImages {
            return self.sectionTitles.count
        } else {
            return self.sectionImages.count
        }
    }
    
    var enlargeEdgeInset = UIEdgeInsets()
    
    // MARK: - Touch Methods
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let touchesLocation = touch?.location(in: self) else {
            assert(false, "Touch Location not found")
            return
        }
        let enlargeRect = CGRect(x: self.bounds.origin.x - self.enlargeEdgeInset.left,
                                 y: self.bounds.origin.y - self.enlargeEdgeInset.top,
                                 width: self.bounds.size.width + self.enlargeEdgeInset.left + self.enlargeEdgeInset.right,
                                 height: self.bounds.size.height + self.enlargeEdgeInset.top + self.enlargeEdgeInset.bottom)
        
        if enlargeRect.contains(touchesLocation) {
            var segment = 0
            if self.segmentWidthStyle == .fixed {
                segment = Int((touchesLocation.x + self.scrollView.contentOffset.x) / self.segmentWidth)
            } else {
                // To know which segment the user touched, we need to loop over the widths and substract it from the x position.
                var widthLeft = touchesLocation.x + self.scrollView.contentOffset.x
                
                if self.fixLast {
                    if widthLeft > (frame.width - self.segmentWidthsArray.last!) {
                        segment = self.segmentWidthsArray.count - 1
                    } else {
                        let new = self.segmentWidthsArray.reduce(0, +) - self.segmentWidthsArray.last!
                        guard widthLeft < new else { return }
                        for width in self.segmentWidthsArray {
                            widthLeft -= width
                            // When we don't have any width left to substract, we have the segment index.
                            if widthLeft <= 0 {
                                break
                            }
                            segment += 1
                        }
                    }
                } else {
                    for width in self.segmentWidthsArray {
                        widthLeft -= width
                        // When we don't have any width left to substract, we have the segment index.
                        if widthLeft <= 0 {
                            break
                        }
                        segment += 1
                    }
                }
            }
            
            var sectionsCount = 0
            if self.type == .images {
                sectionsCount = self.sectionImages.count
            } else {
                sectionsCount = self.sectionTitles.count
            }
            
            if segment == self.selectedSegmentIndex {
                self.sameIndexTouchBlock?(segment)
            }
            
            if segment != self.selectedSegmentIndex && segment < sectionsCount {
                // Check if we have to do anything with the touch event
                self.setSelected(forIndex: segment, animated: true, shouldNotify: true)
            }
        }
    }
    
    // MARK: - Scrolling
    
    private func totalSegmentedControlWidth() -> CGFloat {
        if self.type != .images {
            if self.segmentWidthStyle == .fixed {
                return CGFloat(self.sectionTitles.count) * self.segmentWidth
            } else {
                let sum = self.segmentWidthsArray.reduce(0, +)
                return sum
            }
        } else {
            return CGFloat(self.sectionImages.count) * self.segmentWidth
        }
    }
    
    func scrollToSelectedSegmentIndex(animated: Bool) {
        var rectForSelectedIndex = CGRect.zero
        var selectedSegmentOffset: CGFloat = 0
        if self.segmentWidthStyle == .fixed {
            rectForSelectedIndex = CGRect(x: (self.segmentWidth * CGFloat(self.selectedSegmentIndex)),
                                          y: 0,
                                          width: self.segmentWidth,
                                          height: self.frame.height)
            selectedSegmentOffset = (self.frame.width / 2) - (self.segmentWidth / 2)
        } else {
            var i = 0
            var offsetter: CGFloat = 0
            for width in self.segmentWidthsArray {
                if self.selectedSegmentIndex == i {
                    break
                }
                offsetter += width
                i += 1
            }
            rectForSelectedIndex = CGRect(x: offsetter,
                                          y: 0,
                                          width: self.segmentWidthsArray[self.selectedSegmentIndex],
                                          height: self.frame.height)
            selectedSegmentOffset = (self.frame.width / 2) - (self.segmentWidthsArray[self.selectedSegmentIndex] / 2)
        }
        rectForSelectedIndex.origin.x -= selectedSegmentOffset
        rectForSelectedIndex.size.width += selectedSegmentOffset * 2
        self.scrollView.scrollRectToVisible(rectForSelectedIndex, animated: animated)
    }
    
    // MARK: - Index Change
    
    public func setSelected(forIndex index: Int, animated: Bool) {
        self.setSelected(forIndex: index, animated: animated, shouldNotify: false)
    }
    
    public func setSelected(forIndex index: Int, animated: Bool, shouldNotify: Bool) {
        self.selectedSegmentIndex = index
        self.setNeedsDisplay()
        
        if index == SLSegmentedControlNoSegment {
            self.selectionIndicatorBoxLayer.removeFromSuperlayer()
            self.selectionIndicatorArrowLayer.removeFromSuperlayer()
            self.selectionIndicatorStripLayer.removeFromSuperlayer()
        } else {
            self.scrollToSelectedSegmentIndex(animated: animated)
            
            if animated {
                // If the selected segment layer is not added to the super layer, that means no
                // index is currently selected, so add the layer then move it to the new
                // segment index without animating.
                if self.selectionStyle == .arrow {
                    if self.selectionIndicatorArrowLayer.superlayer == nil {
                        self.scrollView.layer.addSublayer(self.selectionIndicatorArrowLayer)
                        self.setSelected(forIndex: index, animated: false, shouldNotify: true)
                        return
                    }
                } else {
                    if self.selectionIndicatorStripLayer.superlayer == nil {
                        self.scrollView.layer.addSublayer(self.selectionIndicatorStripLayer)
                        if self.selectionStyle == .box && self.selectionIndicatorBoxLayer.superlayer == nil {
                            self.scrollView.layer.insertSublayer(self.selectionIndicatorBoxLayer, at: 0)
                        }
                        self.setSelected(forIndex: index, animated: false, shouldNotify: true)
                        return
                    }
                }
                if shouldNotify {
                    self.notifyForSegmentChange(toIndex: index)
                }
                
                // Restore CALayer animations
                self.selectionIndicatorArrowLayer.actions = nil
                self.selectionIndicatorStripLayer.actions = nil
                self.selectionIndicatorBoxLayer.actions = nil
                
                // Animate to new position
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.15)
                
//                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear))
                self.setArrowFrame()
                self.selectionIndicatorBoxLayer.frame = self.frameForFillerSelectionIndicator()
                self.selectionIndicatorStripLayer.frame = self.frameForSelectionIndicator()
                CATransaction.commit()
                
            } else {
                // Disable CALayer animations
                self.selectionIndicatorArrowLayer.actions = nil
                self.setArrowFrame()
                self.selectionIndicatorStripLayer.actions = nil
                self.selectionIndicatorStripLayer.frame = self.frameForSelectionIndicator()
                self.selectionIndicatorBoxLayer.actions = nil
                self.selectionIndicatorBoxLayer.frame = self.frameForFillerSelectionIndicator()
                if shouldNotify {
                    self.notifyForSegmentChange(toIndex: index)
                }
            }
        }
    }
    
    private func notifyForSegmentChange(toIndex index: Int) {
        if self.superview != nil {
            self.sendActions(for: .valueChanged)
        }
        self._didIndexChange(index)
    }
    
    // MARK: - Styliing Support
    
    private func finalTitleAttributes() -> [NSAttributedString.Key: Any] {
        var defaults: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                                                       NSAttributedString.Key.foregroundColor: UIColor.black]
        if self.titleTextAttributes != nil {
            defaults.merge(dict: self.titleTextAttributes!)
        }
        
        return defaults
    }
    
    private func finalSelectedTitleAttributes() -> [NSAttributedString.Key: Any] {
        var defaults: [NSAttributedString.Key: Any] = self.finalTitleAttributes()
        if self.selectedTitleTextAttributes != nil {
            defaults.merge(dict: self.selectedTitleTextAttributes!)
        }
        return defaults
    }
}
 
extension MSSegmentControl: MXSegmentProtocol {
    // segment change to tell vc
    public var change: ((Int) -> Void) {
        get {
            return self._didIndexChange
        }
        set {
            self._didIndexChange = newValue
        }
    }
    
    // vc change callback method
    public func setSelected(index: Int, animator: Bool) {
        self.setSelected(forIndex: index, animated: animator, shouldNotify: true)
    }
}

class MSScrollView: UIScrollView {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.isDragging {
            self.next?.touchesBegan(touches, with: event)
        } else {
            super.touchesBegan(touches, with: event)
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.isDragging {
            self.next?.touchesMoved(touches, with: event)
        } else {
            super.touchesMoved(touches, with: event)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.isDragging {
            self.next?.touchesEnded(touches, with: event)
        } else {
            super.touchesEnded(touches, with: event)
        }
    }
   
}
extension CGRect {
//    修改高度
    mutating func changeHeightTo(_ value: CGFloat) {
        self.size.height = value
    }
//    修改X
    mutating func changeXTo(_ value: CGFloat) {
        self.origin.x = value
    }
//    修改宽度
    mutating func changeWidthTo(_ value: CGFloat) {
        self.size.width = value
    }
//    修改Y
    mutating func changeYTo(_ value: CGFloat) {
        self.origin.y = value
    }
}

extension Dictionary {
    mutating func merge<K, V>(dict: [K: V]) {
        for (k, v) in dict {
            self.updateValue(v as! Value, forKey: k as! Key)
        }
    }
}
