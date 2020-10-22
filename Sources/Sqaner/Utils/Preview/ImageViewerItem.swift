//
//  ImageViewerItem.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/19/20.
//

import UIKit

@objc public protocol ImageViewerItemDelegate: UIScrollViewDelegate {
    func imageViewerItemDidChangeOrientation(imageViewZoom: ImageViewerItem)
}

public class ImageViewerItem: UIScrollView {
    @objc public enum ScaleMode: Int {
        case aspectFill
        case aspectFit
        case widthFill
        case heightFill
    }

    @objc public enum Offset: Int {
        case begining
        case center
    }

    static let kZoomInFactorFromMinWhenDoubleTap: CGFloat = 2

    @objc private(set) var zoomImageView: UIImageView?

    @objc public var imageContentMode: ScaleMode = .widthFill
    @objc public var initialOffset: Offset = .begining

    @objc public weak var imageViewerItemDelegate: ImageViewerItemDelegate?

    var imageSize: CGSize = CGSize.zero
    private var pointToCenterAfterResize: CGPoint = CGPoint.zero
    private var scaleToRestoreAfterResize: CGFloat = 1.0
    var maxScaleFromMinScale: CGFloat = 3.0

    override open var frame: CGRect {
        willSet {
            if self.frame.equalTo(newValue) == false &&
                newValue.equalTo(CGRect.zero) == false &&
                self.imageSize.equalTo(CGSize.zero) == false {
                self.prepareToResize()
            }
        }

        didSet {
            if self.frame.equalTo(oldValue) == false &&
                self.frame.equalTo(CGRect.zero) == false &&
                self.imageSize.equalTo(CGSize.zero) == false {
                self.recoverFromResizing()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.initialize()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func initialize() {
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollView.DecelerationRate.fast
        self.delegate = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ImageViewerItem.changeOrientationNotification),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc func adjustFrameToCenter() {

        guard let unwrappedZoomView = self.zoomImageView else {
            return
        }

        var frameToCenter = unwrappedZoomView.frame

        // center horizontally
        if frameToCenter.size.width < bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }

        // center vertically
        if frameToCenter.size.height < bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }

        unwrappedZoomView.frame = frameToCenter
    }

    private func prepareToResize() {
        let boundsCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.pointToCenterAfterResize = convert(boundsCenter, to: self.zoomImageView)

        self.scaleToRestoreAfterResize = zoomScale

        if self.scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(Float.ulpOfOne) {
            self.scaleToRestoreAfterResize = 0
        }
    }

    private func recoverFromResizing() {
        self.setMaxMinZoomScalesForCurrentBounds()

        let maxZoomScale = max(minimumZoomScale, self.scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)

        let boundsCenter = self.convert(self.pointToCenterAfterResize, to: self.zoomImageView)

        var offset = CGPoint(x: boundsCenter.x - bounds.size.width/2.0, y: boundsCenter.y - bounds.size.height/2.0)

        let maxOffset = self.maximumContentOffset()
        let minOffset = self.minimumContentOffset()

        var realMaxOffset = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)

        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)

        contentOffset = offset
    }

    private func maximumContentOffset() -> CGPoint {
        return CGPoint(x: contentSize.width - bounds.width, y: contentSize.height - bounds.height)
    }

    private func minimumContentOffset() -> CGPoint {
        return CGPoint.zero
    }

    // MARK: - Set up

    open func setup() {
        var topSupperView = superview

        while topSupperView?.superview != nil {
            topSupperView = topSupperView?.superview
        }

        // Make sure views have already layout with precise frame
        topSupperView?.layoutIfNeeded()
    }

    // MARK: - Display image

    @objc open func display(image: UIImage) {

        if let zoomView = self.zoomImageView {
            zoomView.removeFromSuperview()
        }

        self.zoomImageView = UIImageView(image: image)
        self.zoomImageView!.isUserInteractionEnabled = true
        self.addSubview(self.zoomImageView!)

        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(ImageViewerItem.doubleTapGestureRecognizer(_:))
        )
        tapGesture.numberOfTapsRequired = 2

        self.zoomImageView!.addGestureRecognizer(tapGesture)

        self.configureImageForSize(image.size)
    }

    private func configureImageForSize(_ size: CGSize) {
        self.imageSize = size
        self.contentSize = self.imageSize
        self.setMaxMinZoomScalesForCurrentBounds()
        self.zoomScale = minimumZoomScale

        switch initialOffset {
        case .begining:
            self.contentOffset =  CGPoint.zero
        case .center:
            let xOffset = self.contentSize.width < self.bounds.width ? 0 :
                (self.contentSize.width - self.bounds.width) / 2
            let yOffset = self.contentSize.height < self.bounds.height ? 0 :
                (self.contentSize.height - self.bounds.height) / 2

            switch self.imageContentMode {
            case .aspectFit:
                self.contentOffset =  CGPoint.zero
            case .aspectFill:
                self.contentOffset = CGPoint(x: xOffset, y: yOffset)
            case .heightFill:
                self.contentOffset = CGPoint(x: xOffset, y: 0)
            case .widthFill:
                self.contentOffset = CGPoint(x: 0, y: yOffset)
            }
        }
    }

    private func setMaxMinZoomScalesForCurrentBounds() {
        // calculate min/max zoomscale

        // the scale needed to perfectly fit the image width-wise
        let xScale = self.bounds.width / self.imageSize.width
        // the scale needed to perfectly fit the image height-wise
        let yScale = self.bounds.height / self.imageSize.height

        var minScale: CGFloat = 1

        switch self.imageContentMode {
        case .aspectFill:
            minScale = max(xScale, yScale)
        case .aspectFit:
            minScale = min(xScale, yScale)
        case .widthFill:
            minScale = xScale
        case .heightFill:
            minScale = yScale
        }

        let maxScale = self.maxScaleFromMinScale * minScale

        // don't let minScale exceed maxScale.
        // (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }

        self.maximumZoomScale = maxScale
        // the multiply factor to prevent user cannot scroll page while they use this control in UIPageViewController
        self.minimumZoomScale = minScale * 0.999
    }

    // MARK: - Gesture

    @objc func doubleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // zoom out if it bigger than middle scale point. Else, zoom in
        if zoomScale >= maximumZoomScale / 2.0 {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            let zoomRect = self.zoomRectForScale(
                ImageViewerItem.kZoomInFactorFromMinWhenDoubleTap * minimumZoomScale,
                center: center
            )
            zoom(to: zoomRect, animated: true)
        }
    }

    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero

        zoomRect.size.height = self.frame.size.height / scale
        zoomRect.size.width  = self.frame.size.width  / scale

        // choose an origin so as to get the right center.
        zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)

        return zoomRect
    }

    open func refresh() {
        if let image = self.zoomImageView?.image {
            self.display(image: image)
        }
    }

    // MARK: - Actions

    @objc func changeOrientationNotification() {
        // A weird bug that frames are not update right after orientation changed. Need delay a little bit with async.
        DispatchQueue.main.async {
            self.configureImageForSize(self.imageSize)
            self.imageViewerItemDelegate?.imageViewerItemDidChangeOrientation(imageViewZoom: self)
        }
    }
}

extension ImageViewerItem: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.imageViewerItemDelegate?.scrollViewDidScroll?(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.imageViewerItemDelegate?.scrollViewWillBeginDragging?(scrollView)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.imageViewerItemDelegate?.scrollViewWillEndDragging?(
            scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset
        )
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.imageViewerItemDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.imageViewerItemDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.imageViewerItemDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.imageViewerItemDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.imageViewerItemDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.imageViewerItemDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    @available(iOS 11.0, *)
    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        self.imageViewerItemDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.zoomImageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.adjustFrameToCenter()
        self.imageViewerItemDelegate?.scrollViewDidZoom?(scrollView)
    }

}
