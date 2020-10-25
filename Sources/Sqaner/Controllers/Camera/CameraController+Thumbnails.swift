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

        return CGRect(x: thumbnailsX + xImageView, y: thumbnailsFrame.origin.y, width: 36, height: 36)
    }

    func updateWidthThumbnails() {

        let diff = self.currentItems.count - self.maxThumbnails

        if diff < 0 {

            let xImageView = CGFloat(self.currentItems.count * 40)
            self.thumbnailsWidth.constant = xImageView + 36

            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }

        }
    }

    func addThumbnail(_ image: UIImage?) {

        let diff = self.currentItems.count - self.maxThumbnails

        if diff > 1 {
            let countLabel = self.thumbnailsView.viewWithTag(self.maxThumbnails + 1) as? UILabel
            countLabel?.text = "+\(diff)"

            let imageView = self.thumbnailsView.viewWithTag(self.maxThumbnails) as? UIImageView
            imageView?.image = image
        } else if diff == 1 {
            let xLabel = CGFloat((self.maxThumbnails - 1) * 40)
            let countLabel = UILabel(frame: CGRect(x: xLabel, y: 0, width: 36, height: 36))
            countLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            countLabel.textColor = .white
            countLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            countLabel.textAlignment = .center
            countLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
            countLabel.layer.borderWidth = 0.5
            countLabel.layer.cornerRadius = 6
            countLabel.clipsToBounds = true
            countLabel.text = "+1"
            countLabel.tag = self.maxThumbnails + 1
            countLabel.isUserInteractionEnabled = false
            self.thumbnailsView.addSubview(countLabel)

            let imageView = self.thumbnailsView.viewWithTag(self.maxThumbnails) as? UIImageView
            imageView?.image = image
        } else {
            let xImageView = CGFloat((self.currentItems.count - 1) * 40)
            let imageView = UIImageView(frame: CGRect(x: xImageView, y: 0, width: 36, height: 36))
            imageView.layer.cornerRadius = 6
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.tag = self.currentItems.count
            imageView.image = image
            self.thumbnailsView.addSubview(imageView)

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onThumbnailTap(_:)))
            imageView.addGestureRecognizer(tapGesture)

        }
    }

    func removeThumbnail() {
        let diff = self.currentItems.count - self.maxThumbnails

        if diff > 0 {
            let countLabel = self.thumbnailsView.viewWithTag(self.maxThumbnails + 1) as? UILabel
            countLabel?.text = "+\(diff)"
        } else if diff == 0 {
            let countLabel = self.thumbnailsView.viewWithTag(self.maxThumbnails + 1)
            UIView.animate(withDuration: 0.5) {
                countLabel?.removeFromSuperview()
            }
        } else {
            guard let imageView = self.thumbnailsView.viewWithTag(self.currentItems.count + 1) else {
                return
            }

            let xImageView = CGFloat(self.currentItems.count * 40)
            self.thumbnailsWidth.constant = xImageView - 4

            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                imageView.removeFromSuperview()
            }
        }
    }

    @objc func onThumbnailTap(_ gestureRecognizer: UIGestureRecognizer) {

    }
}
