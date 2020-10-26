//
//  CameraController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit
import AVFoundation

// swiftlint:disable multiple_closures_with_trailing_closure
enum CameraControllerMode {
    case scan(completion: (_ items: [SqanerItem], _ page: Int) -> Void)
    case rescan(_ item: SqanerItem, completion: (_ item: SqanerItem) -> Void)
}

class CameraController: UIViewController {
    var mode: CameraControllerMode!

    var currentItems: [SqanerItem] = [] {
        didSet {
            self.updateUI()
        }
    }

    var currentIndex: Int = 0

    // MARK: UI props
    @IBOutlet weak var previewView: UIView!

    @IBOutlet weak var cropedView: UIView!
    @IBOutlet weak var cropedImageView: UIImageView!

    @IBOutlet var closeButton: UIButton!
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var shootButton: UIButton!

    @IBOutlet var descView: UIView!
    @IBOutlet var descLabel: UILabel!

    @IBOutlet var reshootButton: UIButton!

    @IBOutlet var completeButton: UIButton!

    @IBOutlet var thumbnailsView: UIView!
    @IBOutlet var thumbnailsWidth: NSLayoutConstraint!

    // MARK: Scan props

    let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    var captureSessionManager: CaptureSessionManager?

    // MARK: Thumbnail props

    var maxThumbnails = 5

    /// The view that draws the detected rectangles.
    let quadView = QuadrilateralView()

    /// Whether flash is enabled
    var flashEnabled = false

    let blackFlashView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: UI helpers props

    var descTimer: Timer?

    // MARK: Overrided methods

    override func viewDidLoad() {
        super.viewDidLoad()

        self.prepareScan()
        self.prepareThumbnails()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.isNavigationBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()

        CaptureSession.current.isEditing = false

        self.quadView.removeQuadrilateral()
        self.captureSessionManager?.start()

        UIApplication.shared.isIdleTimerDisabled = true

        self.updateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.videoPreviewLayer.frame = view.layer.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIApplication.shared.isIdleTimerDisabled = false

        self.captureSessionManager?.stop()
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        if device.torchMode == .on {
            self.toggleFlash()
        }
    }

    private func updateBorder(view: UIView, color: UIColor, width: CGFloat) {
        view.layer.borderWidth = width
        view.layer.borderColor = color.cgColor
    }
}

// MARK: UIActions

extension CameraController {
    @IBAction func onCloseButtonTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onFlashButtonTap(_ sender: Any) {
        self.toggleFlash()
    }

    @IBAction func onReshootButtonTap(_ sender: Any) {
        self.currentItems.removeLast()
        self.removeThumbnail()
    }

    @IBAction func onShootButtonTap(_ sender: Any) {
        self.proceedScan()
    }

    @IBAction func onCompleteButtonTap(_ sender: Any) {
        if case .scan(let completion) = self.mode {
            completion(self.currentItems, 0)
        }
    }
}

// MARK: UI updates

extension CameraController {
    func updateUI() {
        let items = self.currentItems
        let count = items.count

        self.reshootButton.isHidden = count == 0
        self.completeButton.isHidden = count == 0
        self.descView.isHidden = count == 0

        self.view.layoutIfNeeded()

        self.showDesc(text: count == 0 ? "Наведите камеру на документ" : "Наведите на следующую страницу")
    }

    func showDesc(text: String) {
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

    func hideDesc() {
        if let timer = descTimer {
            timer.invalidate()
        }

        UIView.animate(withDuration: 0.5) {
            self.descView.layer.opacity = 0
        } completion: { (_) in
            self.descView.isHidden = true
        }
    }

    func hideCropedImage(completion: @escaping (() -> Void)) {

        let transformFrame = self.nextThumbnailFrame()

        var translationX = (self.cropedImageView.frame.width - transformFrame.width)/2.0
        var translationY = (self.cropedImageView.frame.height - transformFrame.height)/2.0

        translationX += self.cropedImageView.frame.origin.x
        translationY += self.cropedImageView.frame.origin.y

        let endpoint = CGPoint(x: transformFrame.origin.x - translationX, y: transformFrame.origin.y - translationY)

        let scaleX = transformFrame.width/self.cropedImageView.frame.width
        let scaleY = transformFrame.height/self.cropedImageView.frame.height

        UIView.animate(withDuration: 0.5, delay: 0, options: .beginFromCurrentState, animations: {
            self.cropedImageView.transform =
                CGAffineTransform(translationX: endpoint.x, y: endpoint.y).scaledBy(x: scaleX, y: scaleY)
        }) { (_) in
            self.cropedImageView.transform = .identity
            self.cropedView.isHidden = true
            completion()
        }
    }
}
