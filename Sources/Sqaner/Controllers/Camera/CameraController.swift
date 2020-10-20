//
//  CameraController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit
import AVFoundation

// swiftlint:disable multiple_closures_with_trailing_closure
internal enum CameraControllerMode {
    case scan(completion: (_ items: [SqanerItem]) -> Void)
    case rescan(_ item: SqanerItem, completion: (_ item: SqanerItem) -> Void)
}

public class CameraController: UIViewController {
    internal var mode: CameraControllerMode!

    internal var currentItems: [SqanerItem] = [] {
        didSet {
            self.updateUI()
        }
    }

    internal var currentIndex: UInt = 0

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

    internal let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    internal var captureSessionManager: CaptureSessionManager?

    /// The view that draws the detected rectangles.
    internal let quadView = QuadrilateralView()

    /// Whether flash is enabled
    internal var flashEnabled = false

    internal let blackFlashView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: UI helpers props

    internal var descTimer: Timer?

    // MARK: Overrided methods

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareScan()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.isNavigationBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()

        CaptureSession.current.isEditing = false

        self.quadView.removeQuadrilateral()
        self.captureSessionManager?.start()

        UIApplication.shared.isIdleTimerDisabled = true

        self.updateUI()
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
        self.currentItems.removeLast()
    }

    @IBAction func onShootButtonTap(_ sender: Any) {
        self.proceedScan()
    }

    @IBAction func onCompleteButtonTap(_ sender: Any) {
        if case .scan(let completion) = self.mode {
            completion(self.currentItems)
        }
    }
}

// MARK: UI updates

extension CameraController {
    internal func updateUI() {
        let items = self.currentItems
        let count = items.count

        self.leftView.isHidden = count == 0
        self.rightView.isHidden = count == 0
        self.descView.isHidden = count == 0
        self.rightDescView.isHidden = count < 2

        if count > 0 {
            self.leftImageView.image = items.last?.resultImage
            self.rightImageView.image = items.last?.resultImage

            if count > 1 {
                self.rightPreImageView.isHidden = false
                self.rightPreImageView.image = items[count - 2].resultImage
                self.rightDescLabel.text = String(count)
            } else {
                self.rightPreImageView.isHidden = true
            }
        }
        self.view.layoutIfNeeded()

        self.showDesc(text: count == 0 ? "Наведите камеру на документ" : "Наведите на следующую страницу")
    }

    internal func showDesc(text: String) {
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

    internal func hideDesc() {
        if let timer = descTimer {
            timer.invalidate()
        }

        UIView.animate(withDuration: 0.5) {
            self.descView.layer.opacity = 0
        } completion: { (_) in
            self.descView.isHidden = true
        }
    }

    internal func hideCropedImage(completion: @escaping (() -> Void)) {
        DispatchQueue.main.async {
            let endpoint = self.rightView.frame.origin

            UIView.animate(withDuration: 0.5, delay: 0, options: .beginFromCurrentState, animations: {
                self.cropedView.layer.opacity = 0
                self.cropedImageView.transform =
                    CGAffineTransform(translationX: endpoint.x, y: endpoint.y).scaledBy(x: 0.05, y: 0.05)
            }) { (_) in
                self.cropedImageView.transform = .identity
                self.cropedView.isHidden = true
                completion()
            }
        }
    }
}
