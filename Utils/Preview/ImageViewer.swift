//
//  ImageViewer.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/19/20.
//

import UIKit

class ImageViewer: UIView {
    var images: [UIImage] = []
    
    var scrollView: UIScrollView!
    
    var pageUpdated: ((_ page: Int) -> Void)?
    
    private var prevPage: Int?
    
    var page: Int {
        return Int(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
    }
    
    var viewHeight: CGFloat {
        return self.bounds.size.height
    }
    
    var viewWidth: CGFloat {
        return self.bounds.size.width
    }
    
    func update(images: [UIImage]) {
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
            let imageView = ImageScrollView(
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
        
        if let page = self.prevPage {
            self.scrollView.setContentOffset(CGPoint(x: self.viewWidth * CGFloat(page), y: 0), animated: false)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.update(images: self.images)
    }
    
    func update(page: UInt, animated: Bool) {
        self.scrollView.setContentOffset(CGPoint(x: self.viewWidth * CGFloat(page), y: 0), animated: animated)
    }
    
    func update(image: UIImage, at page: Int) {
        self.images[page] = image
        self.update(images: self.images)
    }
}

extension ImageViewer: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.prevPage != self.page {
            self.prevPage = self.page
            self.pageUpdated?(self.page)
        }
    }
}
