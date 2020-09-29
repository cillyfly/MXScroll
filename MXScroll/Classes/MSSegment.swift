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
public enum MSSegmentedControlSelectionStyle: Int {
  case textWidth
  case fullWidth
  case box
  case arrow
}

public enum MSSegmentedControlSelectionIndicatorLocation: Int {
  case up
  case down
  case none // No selection indicator
}

public enum MSSegmentedControlSegmentWidthStyle: Int {
  case fixed // Segment width is fixed
  case dynamic // Segment width will only be as big as the text width (including inset)
}

public enum MSSegmentedControlBorderType: Int {
  case none // 0
  case top // (1 << 0)
  case left // (1 << 1)
  case bottom // (1 << 2)
  case right // (1 << 3)
}

public enum MSSegmentedControlType: Int {
  case text
  case images
  case textImages
  case textLeftImages
}

public enum MSSegmentedControlStart {
  // From left
  case left
  case middle
  // From Right
  case right
}

public let SLSegmentedControlNoSegment = -1

public typealias IndexChangeBlock = (Int) -> Void
public typealias MSTitleFormatterBlock = ((_ segmentedControl: MSSegmentControl, _ title: String, _ index: Int, _ selected: Bool) -> NSAttributedString)

public class MSSegmentControl: UIControl {
  private var _didIndexChange: (Int) -> Void = { _ in }

  public var sectionTitles: [String]! {
    didSet {
      updateSegmentsRects()
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  public var sectionImages: [UIImage]! {
    didSet {
      updateSegmentsRects()
      setNeedsLayout()
      setNeedsDisplay()
    }
  }

  public var sectionSelectedImages: [UIImage]!

  /// Call when same Index touched
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
  override open dynamic var backgroundColor: UIColor! {
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
      selectionIndicator.backgroundColor = selectionIndicatorColor
      selectionIndicatorBoxColor = selectionIndicatorColor
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
      if segmentWidthStyle == .dynamic, type == .images {
        segmentWidthStyle = .fixed
      }
    }
  }

  /// segment开始的顺序，可以从左边开始，也可以从右边开始
  public var segmentStart: MSSegmentedControlStart = .left

  /// Specifies the location of the selection indicator.
  /// Default is `up`
  public var selectionIndicatorLocation: MSSegmentedControlSelectionIndicatorLocation = .down {
    didSet {
      if selectionIndicatorLocation == .none {
        selectionIndicatorHeight = 0.0
      }
    }
  }

  /// Specifies the border type.
  /// Default is `none`
  public var borderType: MSSegmentedControlBorderType = .none {
    didSet {
      setNeedsDisplay()
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

  // MARK: Private variable

  internal var selectionIndicatorStripLayer = CALayer()
  internal var selectionIndicatorBoxLayer = CALayer() {
    didSet {
      selectionIndicatorBoxLayer.opacity = selectionIndicatorBoxOpacity
      selectionIndicatorBoxLayer.borderWidth = borderWidthSG
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
    setup()
    sectionTitles = titles
    type = .text
    postInitMethod()
  }

  /// Initialiaze the segmented control with only images/icons.
  ///
  /// - Parameter sectionImages: array of images for the section images.
  /// - Parameter selectedImages: array of images for the selected section images.
  public convenience init(sectionImages images: [UIImage], selectedImages sImages: [UIImage]) {
    self.init()
    setup()
    sectionImages = images
    sectionSelectedImages = sImages
    type = .images
    segmentWidthStyle = .fixed
    postInitMethod()
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
    setup()
    sectionTitles = titles
    sectionImages = images
    sectionSelectedImages = sImages
    type = .textImages

    assert(sectionTitles.count == sectionSelectedImages.count, "Titles and images are not in correct count")
    postInitMethod()
  }

  override open func awakeFromNib() {
    setup()
    postInitMethod()
  }

  private func setup() {
    addSubview(scrollView)
    backgroundColor = UIColor.lightGray
    isOpaque = false
    contentMode = .redraw
  }

  open func postInitMethod() {}

  // MARK: - View LifeCycle

  override open func willMove(toSuperview newSuperview: UIView?) {
    if newSuperview == nil {
      // Control is being removed
      return
    }
    if sectionTitles != nil || sectionImages != nil {
      updateSegmentsRects()
    }
  }

  // MARK: - Drawing

  private func measureTitleAtIndex(index: Int) -> CGSize {
    if index >= sectionTitles.count {
      return CGSize.zero
    }
    let title = sectionTitles[index]

    let selected = (index == selectedSegmentIndex)
    var size = CGSize.zero
    if titleFormatter == nil {
      size = (title as NSString).size(withAttributes: selected ?
        finalSelectedTitleAttributes() : finalTitleAttributes())
    } else {
      size = titleFormatter!(self, title, index, selected).size()
    }
    return size
  }

  private func attributedTitleAtIndex(index: Int) -> NSAttributedString {
    let title = sectionTitles[index]
    let selected = (index == selectedSegmentIndex)
    var str = NSAttributedString()
    if titleFormatter == nil {
      let attr = selected ? finalSelectedTitleAttributes() : finalTitleAttributes()
      str = NSAttributedString(string: title, attributes: attr)
    } else {
      str = titleFormatter!(self, title, index, selected)
    }
    return str
  }

  override open func draw(_ rect: CGRect) {
    backgroundColor.setFill()
    UIRectFill(bounds)

    selectionIndicatorArrowLayer.backgroundColor = selectionIndicatorColor.cgColor
    selectionIndicatorStripLayer.backgroundColor = selectionIndicatorColor.cgColor
    selectionIndicatorBoxLayer.backgroundColor = selectionIndicatorBoxColor.cgColor
    selectionIndicatorBoxLayer.borderColor = selectionIndicatorBoxColor.cgColor

    // Remove all sublayers to avoid drawing images over existing ones
    scrollView.layer.sublayers = nil

    let oldrect = rect
    if type == .text {
      editWithText(oldrect: oldrect)
    } else if type == .images {
      editWithImage(oldrect: oldrect)
    } else if type == .textImages {
      editWithTextImage(oldrect: oldrect)
    } else if type == .textLeftImages {
      editWithTextLeftImage(oldrect: oldrect)
    }

    if sectionTitles == nil {
      return
    }
    // Add the selection indicators
    if selectedSegmentIndex != SLSegmentedControlNoSegment {
      if selectionStyle == .arrow {
        if selectionIndicatorArrowLayer.superlayer == nil {
          setArrowFrame()
          scrollView.layer.addSublayer(selectionIndicatorArrowLayer)
        }
      } else {
        if selectionIndicatorStripLayer.superlayer == nil {
          selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
          scrollView.layer.addSublayer(selectionIndicatorStripLayer)

          if selectionStyle == .box, selectionIndicatorBoxLayer.superlayer == nil {
            selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
            selectionIndicatorBoxLayer.opacity = selectionIndicatorBoxOpacity
            scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, at: 0)
          }
        }
      }
    }
  }

  func editWithText(oldrect: CGRect) {
    if sectionTitles == nil {
      return
    }
    for (index, _) in sectionTitles.enumerated() {
      let size = measureTitleAtIndex(index: index)
      let strWidth = size.width
      let strHeight = size.height
      var rectDiv = CGRect.zero
      var fullRect = CGRect.zero

      // Text inside the CATextLayer will appear blurry unless the rect values are rounded
      let isLocationUp: CGFloat = (selectionIndicatorLocation != .up) ? 0.0 : 1.0
      let isBoxStyle: CGFloat = (selectionStyle != .box) ? 0.0 : 1.0

      let a: CGFloat = (frame.height - (isBoxStyle * selectionIndicatorHeight)) / 2
      let b: CGFloat = (strHeight / 2) + (selectionIndicatorHeight * isLocationUp)
      let yPosition: CGFloat = CGFloat(roundf(Float(a - b)))

      var newRect = CGRect.zero
      if segmentWidthStyle == .fixed {
        let xPosition: CGFloat = CGFloat((segmentWidth * CGFloat(index)) + (segmentWidth - strWidth) / 2)
        newRect = CGRect(x: xPosition,
                         y: yPosition,
                         width: strWidth,
                         height: strHeight)
        rectDiv = calculateRectDiv(at: index, xoffSet: nil)
        fullRect = CGRect(x: segmentWidth * CGFloat(index), y: 0.0, width: segmentWidth, height: oldrect.size.height)
      } else {
        // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
        var xOffset: CGFloat = 0.0
        var i = 0
        for width in segmentWidthsArray {
          if index == i {
            break
          }
          xOffset += width
          i += 1
        }

        let widthForIndex = segmentWidthsArray[index]

        newRect = CGRect(x: xOffset, y: yPosition, width: widthForIndex, height: strHeight)

        fullRect = CGRect(x: segmentWidth * CGFloat(index), y: 0.0, width: widthForIndex, height: oldrect.size.height)
        rectDiv = calculateRectDiv(at: index, xoffSet: xOffset)
      }

      if fixLast, index == sectionTitles.count - 1 {
        newRect = CGRect(x: frame.width - ceil(newRect.size.width), y: ceil(newRect.origin.y), width: ceil(newRect.size.width), height: ceil(newRect.size.height))

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
      titleLayer.string = attributedTitleAtIndex(index: index)
      titleLayer.contentsScale = UIScreen.main.scale
      scrollView.layer.addSublayer(titleLayer)

      // Vertical Divider
      addVerticalLayer(at: index, rectDiv: rectDiv)

      addBgAndBorderLayer(with: fullRect)
    }
  }

  func editWithImage(oldrect _: CGRect) {
    if sectionImages == nil {
      return
    }
    for (index, image) in sectionImages.enumerated() {
      let imageWidth = image.size.width
      let imageHeight = image.size.height

      let a = (frame.height - selectionIndicatorHeight) / 2
      let b = (imageHeight / 2) + (selectionIndicatorLocation == .up ? selectionIndicatorHeight : 0.0)
      let y: CGFloat = CGFloat(roundf(Float(a - b)))
      let x: CGFloat = (segmentWidth * CGFloat(index)) + (segmentWidth - imageWidth) / 2.0
      let newRect = CGRect(x: x, y: y, width: imageWidth, height: imageHeight)

      let imageLayer = CALayer()
      imageLayer.frame = newRect
      imageLayer.contents = image.cgImage

      if selectedSegmentIndex == index, sectionSelectedImages.count > index {
        let highlightedImage = sectionSelectedImages[index]
        imageLayer.contents = highlightedImage.cgImage
      }

      scrollView.layer.addSublayer(imageLayer)

      // vertical Divider
      addVerticalLayer(at: index, rectDiv: calculateRectDiv(at: index, xoffSet: nil))

      addBgAndBorderLayer(with: newRect)
    }
  }

  func editWithTextImage(oldrect _: CGRect) {
    if sectionImages == nil {
      return
    }
    for (index, image) in sectionImages.enumerated() {
      let imageWidth = image.size.width
      let imageHeight = image.size.height

      let stringHeight = measureTitleAtIndex(index: index).height
      let yOffset: CGFloat = CGFloat(roundf(Float(((frame.height - selectionIndicatorHeight) / 2) - (stringHeight / 2))))

      var imagexOffset: CGFloat = edgeInset.left
      var textxOffset: CGFloat = edgeInset.left

      var textWidth: CGFloat = 0.0
      if segmentWidthStyle == .fixed {
        imagexOffset = (segmentWidth * CGFloat(index)) + (segmentWidth / 2) - (imageWidth / 2.0)
        textxOffset = segmentWidth * CGFloat(index)
        textWidth = segmentWidth
      } else {
        // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
        let a = getDynamicWidthTillSegmentIndex(index: index)
        imagexOffset = a.0 + (a.1 / 2) - (imageWidth / 2)
        textxOffset = a.0
        textWidth = segmentWidthsArray[index]
      }

      let imageyOffset: CGFloat = CGFloat(roundf(Float(((frame.height - selectionIndicatorHeight) / 2) + 8.0)))

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
      titleLayer.string = attributedTitleAtIndex(index: index)
      titleLayer.contentsScale = UIScreen.main.scale

      let imageLayer = CALayer()
      imageLayer.frame = imageRect
      imageLayer.contents = image.cgImage
      if selectedSegmentIndex == index, sectionSelectedImages.count > index {
        let highlightedImage = sectionSelectedImages[index]
        imageLayer.contents = highlightedImage.cgImage
      }

      scrollView.layer.addSublayer(imageLayer)
      scrollView.layer.addSublayer(titleLayer)

      addBgAndBorderLayer(with: imageRect)
    }
  }

  func editWithTextLeftImage(oldrect: CGRect) {
    if sectionTitles == nil {
      return
    }
    for (index, _) in sectionTitles.enumerated() {
      let size = measureTitleAtIndex(index: index)
      let strWidth = size.width
      let strHeight = size.height
      var rectDiv = CGRect.zero
      var fullRect = CGRect.zero

      // Text inside the CATextLayer will appear blurry unless the rect values are rounded
      let isLocationUp: CGFloat = (selectionIndicatorLocation != .up) ? 0.0 : 1.0
      let isBoxStyle: CGFloat = (selectionStyle != .box) ? 0.0 : 1.0

      let a: CGFloat = (frame.height - (isBoxStyle * selectionIndicatorHeight)) / 2
      let b: CGFloat = (strHeight / 2) + (selectionIndicatorHeight * isLocationUp)
      let yPosition: CGFloat = CGFloat(roundf(Float(a - b)))

      var newRect = CGRect.zero
      if segmentWidthStyle == .fixed {
        let xPosition: CGFloat = CGFloat((segmentWidth * CGFloat(index)) + (segmentWidth - strWidth) / 2)
        newRect = CGRect(x: xPosition,
                         y: yPosition,
                         width: strWidth,
                         height: strHeight)
        rectDiv = calculateRectDiv(at: index, xoffSet: nil)
        fullRect = CGRect(x: segmentWidth * CGFloat(index), y: 0.0, width: segmentWidth, height: oldrect.size.height)
      } else {
        // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
        var xOffset: CGFloat = 0.0
        var i = 0
        for width in segmentWidthsArray {
          if index == i {
            break
          }
          xOffset += width
          i += 1
        }

        let widthForIndex = segmentWidthsArray[index]

        newRect = CGRect(x: xOffset, y: yPosition, width: widthForIndex, height: strHeight)

        fullRect = CGRect(x: segmentWidth * CGFloat(index), y: 0.0, width: widthForIndex, height: oldrect.size.height)
        rectDiv = calculateRectDiv(at: index, xoffSet: xOffset)
      }
      // Fix rect position/size to avoid blurry labels
      newRect = CGRect(x: ceil(newRect.origin.x), y: ceil(newRect.origin.y), width: ceil(newRect.size.width), height: ceil(newRect.size.height))

      let titleLabel = UILabel()
      titleLabel.frame = newRect
      titleLabel.textAlignment = .left
      titleLabel.attributedText = attributedTitleAtIndex(index: index)
      scrollView.addSubview(titleLabel)

      // Vertical Divider
      addVerticalLayer(at: index, rectDiv: rectDiv)

      addBgAndBorderLayer(with: fullRect)
    }
  }

  private func calculateRectDiv(at index: Int, xoffSet: CGFloat?) -> CGRect {
    var a: CGFloat
    if xoffSet != nil {
      a = xoffSet!
    } else {
      a = segmentWidth * CGFloat(index)
    }
    let xPosition = CGFloat(a - CGFloat(verticalDividerWidth / 2))
    let rectDiv = CGRect(x: xPosition,
                         y: selectionIndicatorHeight * 2,
                         width: CGFloat(verticalDividerWidth),
                         height: frame.size.height - (selectionIndicatorHeight * 4))
    return rectDiv
  }

  // Add Vertical Divider Layer
  private func addVerticalLayer(at index: Int, rectDiv: CGRect) {
    if verticalDividerEnabled, index > 0 {
      let vDivLayer = CALayer()
      vDivLayer.frame = rectDiv
      vDivLayer.backgroundColor = verticalDividerColor.cgColor
      scrollView.layer.addSublayer(vDivLayer)
    }
  }

  private func addBgAndBorderLayer(with rect: CGRect) {
    // Background layer
    let bgLayer = CALayer()
    bgLayer.frame = rect
    layer.insertSublayer(bgLayer, at: 0)

    // Border layer
    if borderType != .none {
      let borderLayer = CALayer()
      borderLayer.backgroundColor = borderColor.cgColor
      var borderRect = CGRect.zero
      switch borderType {
      case .top:
        borderRect = CGRect(x: 0, y: 0, width: rect.size.width, height: borderWidthSG)
      case .left:
        borderRect = CGRect(x: 0, y: 0, width: borderWidthSG, height: rect.size.height)
      case .bottom:
        borderRect = CGRect(x: 0, y: rect.size.height, width: rect.size.width, height: borderWidthSG)
      case .right:
        borderRect = CGRect(x: 0, y: rect.size.width, width: borderWidthSG, height: rect.size.height)
      case .none:
        break
      }
      borderLayer.frame = borderRect
      bgLayer.addSublayer(borderLayer)
    }
  }

  private func setArrowFrame() {
    selectionIndicatorArrowLayer.frame = frameForSelectionIndicator()
    selectionIndicatorArrowLayer.mask = nil

    let arrowPath = UIBezierPath()
    var p1 = CGPoint.zero
    var p2 = CGPoint.zero
    var p3 = CGPoint.zero

    if selectionIndicatorLocation == .down {
      p1 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width / 2, y: 0)
      p2 = CGPoint(x: 0, y: selectionIndicatorArrowLayer.bounds.size.height)
      p3 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width, y: selectionIndicatorArrowLayer.bounds.size.height)
    } else if selectionIndicatorLocation == .up {
      p1 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width / 2, y: selectionIndicatorArrowLayer.bounds.size.height)
      p2 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width, y: 0)
    }
    arrowPath.move(to: p1)
    arrowPath.addLine(to: p2)
    arrowPath.addLine(to: p3)
    arrowPath.close()

    let maskLayer = CAShapeLayer()
    maskLayer.frame = selectionIndicatorArrowLayer.bounds
    maskLayer.path = arrowPath.cgPath
    selectionIndicatorArrowLayer.mask = maskLayer
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
    if selectionIndicatorLocation == .down {
      indicatorYOffset = bounds.size.height - selectionIndicatorHeight + edgeInset.bottom
    } else if selectionIndicatorLocation == .up {
      indicatorYOffset = edgeInset.top
    }
    var sectionWidth: CGFloat = 0.0
    if type == .text {
      sectionWidth = measureTitleAtIndex(index: selectedSegmentIndex).width
    } else if type == .images {
      sectionWidth = sectionImages[selectedSegmentIndex].size.width
    } else if type == .textImages {
      let stringWidth = measureTitleAtIndex(index: selectedSegmentIndex).width
      let imageWidth = sectionImages[selectedSegmentIndex].size.width
      sectionWidth = max(stringWidth, imageWidth)
    }

    var indicatorFrame = CGRect.zero

    if selectionStyle == .arrow {
      var widthToStartOfSelIndex: CGFloat = 0.0
      var widthToEndOfSelIndex: CGFloat = 0.0
      if segmentWidthStyle == .dynamic {
        let a = getDynamicWidthTillSegmentIndex(index: selectedSegmentIndex)
        widthToStartOfSelIndex = a.0
        widthToEndOfSelIndex = widthToStartOfSelIndex + a.1
      } else {
        widthToStartOfSelIndex = CGFloat(selectedSegmentIndex) * segmentWidth
        widthToEndOfSelIndex = widthToStartOfSelIndex + segmentWidth
      }
      let xPos = widthToStartOfSelIndex + ((widthToEndOfSelIndex - widthToStartOfSelIndex) / 2) - selectionIndicatorHeight
      indicatorFrame = CGRect(x: xPos, y: indicatorYOffset, width: selectionIndicatorHeight * 2, height: selectionIndicatorHeight)
    } else {
      if selectionStyle == .textWidth, sectionWidth <= segmentWidth,
        segmentWidthStyle != .dynamic {
        let widthToStartOfSelIndex: CGFloat = CGFloat(selectedSegmentIndex) * segmentWidth
        let widthToEndOfSelIndex: CGFloat = widthToStartOfSelIndex + segmentWidth

        var xPos = (widthToStartOfSelIndex - (sectionWidth / 2)) + ((widthToEndOfSelIndex - widthToStartOfSelIndex) / 2)
        xPos += edgeInset.left
        indicatorFrame = CGRect(x: xPos, y: indicatorYOffset, width: sectionWidth - edgeInset.right, height: selectionIndicatorHeight)
      } else {
        if segmentWidthStyle == .dynamic {
          var selectedSegmentOffset: CGFloat = 0
          var i = 0
          for width in segmentWidthsArray {
            if selectedSegmentIndex == i {
              break
            }
            selectedSegmentOffset += width
            i += 1
          }
          guard segmentWidthsArray.count > selectedSegmentIndex else { return indicatorFrame }
          indicatorFrame = CGRect(x: selectedSegmentOffset + edgeInset.left,
                                  y: indicatorYOffset,
                                  width: segmentWidthsArray[selectedSegmentIndex] - edgeInset.right - edgeInset.left,
                                  height: selectionIndicatorHeight + edgeInset.bottom)
          if fixLast, segmentWidthsArray.count == selectedSegmentIndex + 1 {
            indicatorFrame.changeXTo(frame.size.width - segmentWidthsArray[selectedSegmentIndex] + edgeInset.right)
          }
        } else {
          let xPos = (segmentWidth * CGFloat(selectedSegmentIndex)) + edgeInset.left
          indicatorFrame = CGRect(x: xPos, y: indicatorYOffset, width: segmentWidth - edgeInset.right - edgeInset.left, height: selectionIndicatorHeight)
        }
      }
    }

    if selectionStyle != .arrow {
      let currentIndicatorWidth = indicatorFrame.size.width
      let widthToMinus = CGFloat(1 - indicatorWidthPercent) * currentIndicatorWidth
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
    for width in segmentWidthsArray {
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
    if segmentWidthStyle == .dynamic {
      var selectedSegmentOffset: CGFloat = 0
      var i = 0
      for width in segmentWidthsArray {
        if selectedSegmentIndex == i {
          break
        }
        selectedSegmentOffset += width
        i += 1
      }

      return CGRect(x: selectedSegmentOffset, y: 0, width: segmentWidthsArray[selectedSegmentIndex], height: frame.height)
    }
    return CGRect(x: segmentWidth * CGFloat(selectedSegmentIndex), y: 0, width: segmentWidth, height: frame.height)
  }

  private func updateSegmentsRects() {
    scrollView.contentInset = UIEdgeInsets.zero
    layoutIfNeeded()
    scrollView.frame = CGRect(origin: CGPoint.zero, size: frame.size)

    let count = sectionCount()
    if count > 0 {
      segmentWidth = frame.size.width / CGFloat(count)
    }

    if type == .text {
      if segmentWidthStyle == .fixed {
        for (index, _) in sectionTitles.enumerated() {
          let stringWidth = measureTitleAtIndex(index: index).width +
            edgeInset.left + edgeInset.right
          segmentWidth = max(stringWidth, segmentWidth)
        }
      } else if segmentWidthStyle == .dynamic {
        var arr = [CGFloat]()
        for (index, _) in sectionTitles.enumerated() {
          let stringWidth = measureTitleAtIndex(index: index).width +
            edgeInset.left + edgeInset.right
          arr.append(stringWidth)
        }
        segmentWidthsArray = arr
      }
    } else if type == .images {
      for image in sectionImages {
        let imageWidth = image.size.width + edgeInset.left + edgeInset.right
        segmentWidth = max(imageWidth, segmentWidth)
      }
    } else if type == .textImages {
      if segmentWidthStyle == .fixed {
        for (index, _) in sectionTitles.enumerated() {
          let stringWidth = measureTitleAtIndex(index: index).width +
            edgeInset.left + edgeInset.right
          segmentWidth = max(stringWidth, segmentWidth)
        }
      } else if segmentWidthStyle == .dynamic {
        var arr = [CGFloat]()
        for (index, _) in sectionTitles.enumerated() {
          let stringWidth = measureTitleAtIndex(index: index).width +
            edgeInset.right
          let imageWidth = sectionImages[index].size.width + edgeInset.left
          arr.append(max(stringWidth, imageWidth))
        }
        segmentWidthsArray = arr
      }
    }
    scrollView.isScrollEnabled = true
    scrollView.contentSize = CGSize(width: totalSegmentedControlWidth(), height: frame.height)
  }

  private func sectionCount() -> Int {
    if type == .text || type == .textLeftImages {
      return sectionTitles.count
    } else {
      return sectionImages.count
    }
  }

  var enlargeEdgeInset = UIEdgeInsets()

  // MARK: - Touch Methods

  override open func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
    let touch = touches.first
    guard let touchesLocation = touch?.location(in: self) else {
      assert(false, "Touch Location not found")
      return
    }
    let enlargeRect = CGRect(x: bounds.origin.x - enlargeEdgeInset.left,
                             y: bounds.origin.y - enlargeEdgeInset.top,
                             width: bounds.size.width + enlargeEdgeInset.left + enlargeEdgeInset.right,
                             height: bounds.size.height + enlargeEdgeInset.top + enlargeEdgeInset.bottom)

    if enlargeRect.contains(touchesLocation) {
      var segment = 0
      if segmentWidthStyle == .fixed {
        segment = Int((touchesLocation.x + scrollView.contentOffset.x) / segmentWidth)
      } else {
        // To know which segment the user touched, we need to loop over the widths and substract it from the x position.
        var widthLeft = touchesLocation.x + scrollView.contentOffset.x

        if fixLast {
          if widthLeft > (frame.width - segmentWidthsArray.last!) {
            segment = segmentWidthsArray.count - 1
          } else {
            let new = segmentWidthsArray.reduce(0, +) - segmentWidthsArray.last!
            guard widthLeft < new else { return }
            for width in segmentWidthsArray {
              widthLeft -= width
              // When we don't have any width left to substract, we have the segment index.
              if widthLeft <= 0 {
                break
              }
              segment += 1
            }
          }
        } else {
          for width in segmentWidthsArray {
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
      if type == .images {
        sectionsCount = sectionImages.count
      } else {
        sectionsCount = sectionTitles.count
      }

      if segment == selectedSegmentIndex {
        sameIndexTouchBlock?(segment)
      }

      if segment != selectedSegmentIndex, segment < sectionsCount {
        // Check if we have to do anything with the touch event
        setSelected(forIndex: segment, animated: true, shouldNotify: true)
      }
    }
  }

  // MARK: - Scrolling

  private func totalSegmentedControlWidth() -> CGFloat {
    if type != .images {
      if segmentWidthStyle == .fixed {
        return CGFloat(sectionTitles.count) * segmentWidth
      } else {
        let sum = segmentWidthsArray.reduce(0, +)
        return sum
      }
    } else {
      return CGFloat(sectionImages.count) * segmentWidth
    }
  }

  func scrollToSelectedSegmentIndex(animated: Bool) {
    var rectForSelectedIndex = CGRect.zero
    var selectedSegmentOffset: CGFloat = 0
    if segmentWidthStyle == .fixed {
      rectForSelectedIndex = CGRect(x: segmentWidth * CGFloat(selectedSegmentIndex),
                                    y: 0,
                                    width: segmentWidth,
                                    height: frame.height)
      selectedSegmentOffset = (frame.width / 2) - (segmentWidth / 2)
    } else {
      var i = 0
      var offsetter: CGFloat = 0
      for width in segmentWidthsArray {
        if selectedSegmentIndex == i {
          break
        }
        offsetter += width
        i += 1
      }
      rectForSelectedIndex = CGRect(x: offsetter,
                                    y: 0,
                                    width: segmentWidthsArray[selectedSegmentIndex],
                                    height: frame.height)
      selectedSegmentOffset = (frame.width / 2) - (segmentWidthsArray[selectedSegmentIndex] / 2)
    }
    rectForSelectedIndex.origin.x -= selectedSegmentOffset
    rectForSelectedIndex.size.width += selectedSegmentOffset * 2
    scrollView.scrollRectToVisible(rectForSelectedIndex, animated: animated)
  }

  // MARK: - Index Change

  public func setSelected(forIndex index: Int, animated: Bool) {
    setSelected(forIndex: index, animated: animated, shouldNotify: false)
  }

  public func setSelected(forIndex index: Int, animated: Bool, shouldNotify: Bool) {
    selectedSegmentIndex = index
    setNeedsDisplay()

    if index == SLSegmentedControlNoSegment {
      selectionIndicatorBoxLayer.removeFromSuperlayer()
      selectionIndicatorArrowLayer.removeFromSuperlayer()
      selectionIndicatorStripLayer.removeFromSuperlayer()
    } else {
      scrollToSelectedSegmentIndex(animated: animated)

      if animated {
        // If the selected segment layer is not added to the super layer, that means no
        // index is currently selected, so add the layer then move it to the new
        // segment index without animating.
        if selectionStyle == .arrow {
          if selectionIndicatorArrowLayer.superlayer == nil {
            scrollView.layer.addSublayer(selectionIndicatorArrowLayer)
            setSelected(forIndex: index, animated: false, shouldNotify: true)
            return
          }
        } else {
          if selectionIndicatorStripLayer.superlayer == nil {
            scrollView.layer.addSublayer(selectionIndicatorStripLayer)
            if selectionStyle == .box, selectionIndicatorBoxLayer.superlayer == nil {
              scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, at: 0)
            }
            setSelected(forIndex: index, animated: false, shouldNotify: true)
            return
          }
        }
        if shouldNotify {
          notifyForSegmentChange(toIndex: index)
        }

        // Restore CALayer animations
        selectionIndicatorArrowLayer.actions = nil
        selectionIndicatorStripLayer.actions = nil
        selectionIndicatorBoxLayer.actions = nil

        // Animate to new position
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)

//                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear))
        setArrowFrame()
        selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
        selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
        CATransaction.commit()

      } else {
        // Disable CALayer animations
        selectionIndicatorArrowLayer.actions = nil
        setArrowFrame()
        selectionIndicatorStripLayer.actions = nil
        selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
        selectionIndicatorBoxLayer.actions = nil
        selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
        if shouldNotify {
          notifyForSegmentChange(toIndex: index)
        }
      }
    }
  }

  private func notifyForSegmentChange(toIndex index: Int) {
    if superview != nil {
      sendActions(for: .valueChanged)
    }
    _didIndexChange(index)
  }

  // MARK: - Styliing Support

  private func finalTitleAttributes() -> [NSAttributedString.Key: Any] {
    var defaults: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                                                   NSAttributedString.Key.foregroundColor: UIColor.black]
    if titleTextAttributes != nil {
      defaults.merge(dict: titleTextAttributes!)
    }

    return defaults
  }

  private func finalSelectedTitleAttributes() -> [NSAttributedString.Key: Any] {
    var defaults: [NSAttributedString.Key: Any] = finalTitleAttributes()
    if selectedTitleTextAttributes != nil {
      defaults.merge(dict: selectedTitleTextAttributes!)
    }
    return defaults
  }
}

extension MSSegmentControl: MXSegmentProtocol {
  // segment change to tell vc
  public var change: (Int) -> Void {
    get {
      return _didIndexChange
    }
    set {
      _didIndexChange = newValue
    }
  }

  // vc change callback method
  public func setSelected(index: Int, animator: Bool) {
    setSelected(forIndex: index, animated: animator, shouldNotify: true)
  }
}

class MSScrollView: UIScrollView {
  override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if !isDragging {
      next?.touchesBegan(touches, with: event)
    } else {
      super.touchesBegan(touches, with: event)
    }
  }

  override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    if !isDragging {
      next?.touchesMoved(touches, with: event)
    } else {
      super.touchesMoved(touches, with: event)
    }
  }

  override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if !isDragging {
      next?.touchesEnded(touches, with: event)
    } else {
      super.touchesEnded(touches, with: event)
    }
  }
}

extension CGRect {
//    修改高度
  mutating func changeHeightTo(_ value: CGFloat) {
    size.height = value
  }

//    修改X
  mutating func changeXTo(_ value: CGFloat) {
    origin.x = value
  }

//    修改宽度
  mutating func changeWidthTo(_ value: CGFloat) {
    size.width = value
  }

//    修改Y
  mutating func changeYTo(_ value: CGFloat) {
    origin.y = value
  }
}

extension Dictionary {
  mutating func merge<K, V>(dict: [K: V]) {
    for (k, v) in dict {
      updateValue(v as! Value, forKey: k as! Key)
    }
  }
}
