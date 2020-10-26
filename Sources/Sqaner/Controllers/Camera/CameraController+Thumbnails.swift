//
//  CameraController+Thumbnails.swift
//  Sqaner
//
//  Created by Андрей Масалкин on 25.10.2020.
//

import UIKit

// MARK: Thumbnails setup

extension CameraController {

    func prepareThumbnails() {

        self.maxThumbnails = Int((UIScreen.main.bounds.width - 124)/40.0)

        self.thumbnailsWidth.constant = 0
    }

    func nextThumbnailFrame() -> CGRect {

        var thumbnailCount = self.currentItems.count
        if thumbnailCount > self.maxThumbnails - 1 {
            thumbnailCount = self.maxThumbnails - 1
        }

        let xImageView = CGFloat(thumbnailCount * 40)

        let thumbnailsFrame = self.thumbnailsView.convert(CGRect(x: 0, y: 0, width: 0, height: 36), to: self.view)

        let thumbnailsWidth = xImageView + 36

        let thumbnailsX = (self.view.frame.width - thumbnailsWidth)/2.0

        return CGRect(x: thumbnailsX, y: thumbnailsFrame.origin.y, width: 36, height: 36)
    }

    func updateWidthThumbnails() {

        var thumbnailCount = self.currentItems.count
        if thumbnailCount > self.maxThumbnails - 1 {
            thumbnailCount = self.maxThumbnails - 1
        }

        let xImageView = CGFloat(thumbnailCount * 40)
        self.thumbnailsWidth.constant = xImageView + 36

        UIView.animate(withDuration: 0.25) {
            self.thumbnailsView.subviews.forEach {
                if ($0 as? UILabel) == nil {
                    if $0.tag + self.maxThumbnails > self.currentItems.count + 1 {
                        var frame = $0.frame
                        frame.origin.x += 40
                        $0.frame = frame
                    } else {
                        $0.layer.opacity = 0
                    }
                }
            }
            self.view.layoutIfNeeded()
        }
    }

    func addThumbnail(_ image: UIImage?) {

        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        imageView.layer.cornerRadius = 6
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.tag = self.currentItems.count
        imageView.image = image
        imageView.isUserInteractionEnabled = true

        UIView.animate(withDuration: 0.5) {
            self.thumbnailsView.addSubview(imageView)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onThumbnailTap(_:)))
        imageView.addGestureRecognizer(tapGesture)

        let diff = self.currentItems.count - self.maxThumbnails
        if diff > 1 {
            if let countLabel = self.thumbnailsView.viewWithTag(9999) as? UILabel {
                countLabel.text = "+\(diff)"
                self.thumbnailsView.bringSubviewToFront(countLabel)
            }
        } else if diff == 1 {
            let xLabel = CGFloat((self.maxThumbnails - 1) * 40)
            let countLabel = UILabel(frame: CGRect(x: xLabel, y: 0, width: 36, height: 36))
            countLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            countLabel.textColor = .white
            countLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            countLabel.textAlignment = .center
            countLabel.layer.cornerRadius = 6
            countLabel.clipsToBounds = true
            countLabel.text = "+1"
            countLabel.tag = 9999
            countLabel.isUserInteractionEnabled = false
            self.thumbnailsView.addSubview(countLabel)
            self.thumbnailsView.bringSubviewToFront(countLabel)
        }
    }

    func removeThumbnail() {

        guard let imageView = self.thumbnailsView.viewWithTag(self.currentItems.count + 1) else {
            return
        }

        var thumbnailCount = self.currentItems.count
        if thumbnailCount > self.maxThumbnails {
            thumbnailCount = self.maxThumbnails
        }

        let xImageView = CGFloat(thumbnailCount * 40)
        self.thumbnailsWidth.constant = xImageView - 4

        UIView.animate(withDuration: 0.5) {
            imageView.removeFromSuperview()
            self.view.layoutIfNeeded()
            self.thumbnailsView.subviews.forEach {
                if ($0 as? UILabel) == nil {
                    if $0.tag > self.currentItems.count - self.maxThumbnails + 1 {
                        var frame = $0.frame
                        frame.origin.x -= 40
                        $0.frame = frame
                    } else if $0.tag == self.currentItems.count - self.maxThumbnails + 1 {
                        $0.layer.opacity = 1
                    }
                }
            }
        }

        let diff = self.currentItems.count - self.maxThumbnails

        if diff > 0 {
            let countLabel = self.thumbnailsView.viewWithTag(9999) as? UILabel
            countLabel?.text = "+\(diff)"
        } else if diff == 0 {
            let countLabel = self.thumbnailsView.viewWithTag(9999)
            UIView.animate(withDuration: 0.5) {
                countLabel?.removeFromSuperview()
            }
        }
    }

    @objc func onThumbnailTap(_ gestureRecognizer: UIGestureRecognizer) {

        if case .scan(let completion) = self.mode {
            completion(self.currentItems, (gestureRecognizer.view?.tag ?? 0) - 1)
        }
    }
}
