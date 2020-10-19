//
//  CameraController+Scan.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/19/20.
//

import UIKit

// MARK: Scan setup

internal extension CameraController {
    internal func prepareScan() {
        self.cropedView.isHidden = true
        
        self.captureSessionManager = CaptureSessionManager(videoPreviewLayer: self.videoPreviewLayer, delegate: self)
        self.previewView.backgroundColor = .darkGray
        self.previewView.layer.addSublayer(self.videoPreviewLayer)
        self.quadView.translatesAutoresizingMaskIntoConstraints = false
        self.quadView.editable = false
        self.previewView.addSubview(self.quadView)
        
        self.previewView.addSubview(self.blackFlashView)
        
        self.setupConstraints()
    }
    
    internal func setupConstraints() {
        var quadViewConstraints = [NSLayoutConstraint]()
        
        quadViewConstraints = [
            self.quadView.topAnchor.constraint(equalTo: self.previewView.topAnchor),
            self.previewView.bottomAnchor.constraint(equalTo: self.quadView.bottomAnchor),
            self.previewView.trailingAnchor.constraint(equalTo: self.quadView.trailingAnchor),
            self.quadView.leadingAnchor.constraint(equalTo: self.previewView.leadingAnchor)
        ]
        
        let blackFlashViewConstraints = [
            self.blackFlashView.topAnchor.constraint(equalTo: self.previewView.topAnchor),
            self.blackFlashView.leadingAnchor.constraint(equalTo: self.previewView.leadingAnchor),
            self.previewView.bottomAnchor.constraint(equalTo: self.blackFlashView.bottomAnchor),
            self.previewView.trailingAnchor.constraint(equalTo: self.blackFlashView.trailingAnchor)
        ]
        
        NSLayoutConstraint.activate(quadViewConstraints + blackFlashViewConstraints)
    }
    
    internal func proceedScan() {
        // Prepare UI
        
        self.shootButton.isUserInteractionEnabled = false
        self.flashToBlack()
        self.quadView.isHidden = true
        self.hideDesc()
        
        self.captureSessionManager?.capturePhoto()
        
        // Then look at :didCapturePicture delegate
    }
    
    internal func toggleFlash() {
        let state = CaptureSession.current.toggleFlash()
        
        switch state {
        case .on:
            self.flashEnabled = true
            self.flashButton.isSelected = true
        case .off:
            self.flashEnabled = false
            self.flashButton.isSelected = false
        case .unknown, .unavailable:
            self.flashEnabled = false
            self.flashButton.isSelected = false
        }
    }
    
    internal func flashToBlack() {
        self.view.bringSubviewToFront(self.blackFlashView)
        self.blackFlashView.isHidden = false
        let flashDuration = DispatchTime.now() + 0.1
        DispatchQueue.main.asyncAfter(deadline: flashDuration) {
            self.blackFlashView.isHidden = true
        }
    }
    
    @objc internal func didSessionItemsUpdate() {
        self.updateUI()
    }
}

extension CameraController: RectangleDetectionDelegateProtocol {
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didFailWithError error: Error) {
        self.shootButton.isUserInteractionEnabled = true
    }
    
    func didStartCapturingPicture(for captureSessionManager: CaptureSessionManager) {
//        self.captureSessionManager?.stop()
        self.shootButton.isUserInteractionEnabled = false
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager,
                               didCapturePicture picture: UIImage,
                               withQuad quad: Quadrilateral?) {
        DispatchQueue.main.async {
            let item = SqanerItem(index: self.currentIndex, image: picture)
            
            let voidBlock = {
                self.cropedView.isHidden = false
                self.cropedView.layer.opacity = 0
                self.cropedImageView.image = item.resultImage
                
                if case .rescan(let reshootItem, let completion) = self.mode {
                    var reshootItem = reshootItem
                    reshootItem.rawImage = item.rawImage
                    reshootItem.resultImage = item.resultImage
                    reshootItem.quad = item.quad
                    self.dismiss(animated: true) {
                        completion(reshootItem)
                    }
                } else {
                    UIView.animate(withDuration: 0.25) {
                        self.cropedView.layer.opacity = 1
                    } completion: { (_) in
                        DispatchQueue.global().async {
                            sleep(2)
                            self.hideCropedImage {
                                self.currentItems.append(item)
                                Sqaner.cameraDidShoot(item)
                                self.shootButton.isUserInteractionEnabled = true
                                self.quadView.isHidden = false
                                self.captureSessionManager?.start()
                            }
                        }
                    }
                }
            }
            
            if let quad = quad {
                item.quad = quad
                item.crop { (cropedImage) in
                    item.resultImage = cropedImage
                    voidBlock()
                }
            } else {
                item.resultImage = picture
                voidBlock()
            }
        }
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager,
                               didDetectQuad quad: Quadrilateral?,
                               _ imageSize: CGSize) {
        guard let quad = quad else {
            // If no quad has been detected, we remove the currently displayed on on the quadView.
            self.quadView.removeQuadrilateral()
            return
        }
        
        let portraitImageSize = CGSize(width: imageSize.height, height: imageSize.width)
        
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: portraitImageSize, aspectFillInSize: self.quadView.bounds.size)
        let scaledImageSize = imageSize.applying(scaleTransform)
        
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)

        let imageBounds = CGRect(origin: .zero, size: scaledImageSize).applying(rotationTransform)

        let translationTransform = CGAffineTransform.translateTransform(fromCenterOfRect: imageBounds, toCenterOfRect: self.quadView.bounds)
        
        let transforms = [scaleTransform, rotationTransform, translationTransform]
        
        let transformedQuad = quad.applyTransforms(transforms)
        
        self.quadView.drawQuadrilateral(quad: transformedQuad, animated: true)
    }
    
}
