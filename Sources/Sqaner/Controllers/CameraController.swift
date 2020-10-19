//
//  CameraController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit
import AVFoundation

public class CameraController: UIViewController {
    private var currentIndex: UInt = 0
    
    // MARK: UI props
    @IBOutlet weak var previewView: UIView!
    
    @IBOutlet weak var cropedView: UIView!
    @IBOutlet weak var cropedImageView: UIImageView!
    
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var shootButton: UIButton!
    
    @IBOutlet var descView: UIView!
    @IBOutlet var descLabel: UILabel!
    
    @IBOutlet var leftView: UIView!
    @IBOutlet var leftImageView: UIImageView!
    
    @IBOutlet var rightView: UIView!
    @IBOutlet var rightPreImageView: UIImageView!
    @IBOutlet var rightImageView: UIImageView!
    @IBOutlet var rightDescView: UIView!
    @IBOutlet var rightDescLabel: UILabel!
    
    // MARK: Scan props
    
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var captureSessionManager: CaptureSessionManager?
    
    /// The view that draws the detected rectangles.
    private let quadView = QuadrilateralView()
        
    /// Whether flash is enabled
    private var flashEnabled = false
    
    private let blackFlashView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: Overrided methods
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareScan()
        self.updateUI()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        
        CaptureSession.current.isEditing = false
        
        self.quadView.removeQuadrilateral()
        self.captureSessionManager?.start()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didSessionItemsUpdate),
            name: NSNotification.Name.Sqaner.sessionItemsUpdate,
            object: nil
        )
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.videoPreviewLayer.frame = view.layer.bounds
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        self.captureSessionManager?.stop()
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        if device.torchMode == .on {
            self.toggleFlash()
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Private methods
    
    private func updateUI() {
        let items = Sqaner.sessionItems
        let count = items.count
        
        self.leftView.isHidden = count == 0
        self.rightView.isHidden = count == 0
        self.descView.isHidden = count == 0
        self.rightDescView.isHidden = count < 2
        
        if count > 0 {
            self.leftImageView.image = items.last?.cropedImage
            self.rightImageView.image = items.last?.cropedImage
            
            if count > 1 {
                self.rightPreImageView.isHidden = false
                self.rightPreImageView.image = items[count - 2].cropedImage
                self.rightDescLabel.text = String(count)
            } else {
                self.rightPreImageView.isHidden = true
            }
        }
        self.view.layoutIfNeeded()
        
        self.showDesc(text: count == 0 ? "Наведите камеру на документ" : "Наведите на следующую страницу")
    }
    
    private var descTimer: Timer?
    
    private func showDesc(text: String) {
        if let timer = descTimer {
            timer.invalidate()
        }
        
        Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { (_) in
            self.hideDesc()
        }
        
        self.descView.isHidden = false
        self.descView.layer.opacity = 0
        self.descLabel.text = text
        
        UIView.animate(withDuration: 0.5) {
            self.descView.layer.opacity = 1
        }
    }
    
    private func hideDesc() {
        if let timer = descTimer {
            timer.invalidate()
        }
        
        UIView.animate(withDuration: 0.5) {
            self.descView.layer.opacity = 0
        } completion: { (_) in
            self.descView.isHidden = true
        }
    }
    
    private func hideCropedImage(completion: @escaping (() -> Void)) {
        DispatchQueue.main.async {
            let endpoint = self.rightView.frame.origin
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .beginFromCurrentState, animations: {
                self.cropedView.layer.opacity = 0
                self.cropedImageView.transform = CGAffineTransform(translationX: endpoint.x, y: endpoint.y).scaledBy(x: 0.05, y: 0.05)
            }) { (_) in
                self.cropedImageView.transform = .identity
                self.cropedView.isHidden = true
                completion()
            }
        }
    }
}

// MARK: UIActions

public extension CameraController {
    @IBAction func onCloseButtonTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onFlashButtonTap(_ sender: Any) {
        self.toggleFlash()
    }
    
    @IBAction func onReshootButtonTap(_ sender: Any) {
        Sqaner.sessionItems.removeLast()
    }
    
    @IBAction func onShootButtonTap(_ sender: Any) {
        self.shootButton.isUserInteractionEnabled = false
        self.flashToBlack()
        self.captureSessionManager?.capturePhoto()
        self.quadView.isHidden = true
        self.hideDesc()
    }
    
    @IBAction func onCompleteButtonTap(_ sender: Any) {
        Sqaner.preview(items: [], presenter: self)
    }
}

// MARK: Scan setup

private extension CameraController {
    private func prepareScan() {
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
    
    private func setupConstraints() {
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
    
    private func toggleFlash() {
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
    
    private func flashToBlack() {
        self.view.bringSubviewToFront(self.blackFlashView)
        self.blackFlashView.isHidden = false
        let flashDuration = DispatchTime.now() + 0.1
        DispatchQueue.main.asyncAfter(deadline: flashDuration) {
            self.blackFlashView.isHidden = true
        }
    }
    
    @objc private func didSessionItemsUpdate() {
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
                self.cropedImageView.image = item.cropedImage
                
                UIView.animate(withDuration: 0.25) {
                    self.cropedView.layer.opacity = 1
                } completion: { (_) in
                    DispatchQueue.global().async {
                        sleep(2)
                        self.hideCropedImage {
                            Sqaner.sessionItems.append(item)
                            Sqaner.cameraDidShoot(item)
                            self.shootButton.isUserInteractionEnabled = true
                            self.quadView.isHidden = false
                            self.captureSessionManager?.start()
                        }
                    }
                }
            }
            
            if let quad = quad {
                item.quad = quad
                item.crop { (cropedImage) in
                    item.cropedImage = cropedImage
                    voidBlock()
                }
            } else {
                item.cropedImage = picture
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
