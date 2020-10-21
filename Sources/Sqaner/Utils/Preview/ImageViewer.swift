//
//  ImageViewer.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/19/20.
//

import UIKit

public class ImageViewer: UIView {
    public var images: [UIImage] = []
    public var scrollView: UIScrollView!
    public var pageUpdated: ((_ page: Int) -> Void)?

    public var page: Int {
        return Int(self.scrollView.contentOffset.x / self.scrollView.frame.size.width)
    }
    
    private var prevPage: Int?

    private var viewHeight: CGFloat {
        return self.bounds.size.height
    }

    private var viewWidth: CGFloat {
        return self.bounds.size.width
    }

    public func update(images: [UIImage], page: Int = 0) {
        self.layer.masksToBounds = true
        self.images = images

        self.subviews.forEach { subview in
            subview.removeFromSuperview()
        }

        self.scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.viewWidth, height: self.viewHeight))
        self.scrollView.delegate = self
        self.scrollView.isPagingEnabled = true

        var xPostion: CGFloat = 0

        for image in images {
            let view = UIView(frame: CGRect(x: xPostion, y: 0, width: self.viewWidth, height: self.viewHeight))

            xPostion += self.viewWidth
            let imageView = ImageViewerItem(
                frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
            )

            imageView.setup()
            imageView.imageContentMode = .aspectFit
            imageView.initialOffset = .center
            imageView.display(image: image)
            imageView.backgroundColor = .clear
            imageView.layer.masksToBounds = true

            view.addSubview(imageView)
            self.scrollView.showsVerticalScrollIndicator = false
            self.scrollView.showsHorizontalScrollIndicator = false
            self.scrollView.addSubview(view)
        }

        self.scrollView.contentSize = CGSize(width: xPostion, height: self.viewHeight)

        self.addSubview(self.scrollView)

        self.prevPage = page
        self.scrollView.setContentOffset(CGPoint(x: self.viewWidth * CGFloat(page), y: 0), animated: false)
    }

    public func update(page: UInt, animated: Bool) {
        self.scrollView.setContentOffset(CGPoint(x: self.viewWidth * CGFloat(page), y: 0), animated: animated)
    }

    public func update(image: UIImage, at page: Int) {
        self.images[page] = image
        self.update(images: self.images)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()

        if let page = self.prevPage {
            self.update(images: self.images, page: page)
        }
    }
}

extension ImageViewer: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.prevPage != self.page {
            self.prevPage = self.page
            self.pageUpdated?(self.page)
        }
    }
}
