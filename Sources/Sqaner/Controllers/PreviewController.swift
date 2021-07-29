//
//  PreviewController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class PreviewController: UIViewController {
    var initialPage: Int = 0
    var rescanEnabled = false
    var completion: ((_ items: [SqanerItem]) -> Void)?

    @IBOutlet public weak var imageViewer: ImageViewer!
    @IBOutlet public weak var toolbar: UIToolbar!
    @IBOutlet public weak var doneButton: UIButton!
    @IBOutlet private weak var closeBarButton: UIBarButtonItem!
    @IBOutlet private weak var fillBarButton: UIBarButtonItem!
    @IBOutlet private weak var cropBarButton: UIBarButtonItem!
    @IBOutlet private weak var rotateBarButton: UIBarButtonItem!
    @IBOutlet private weak var enhanceBarButton: UIBarButtonItem!
    @IBOutlet private weak var deleteBarButton: UIBarButtonItem!

    var currentItems: [SqanerItem] = [] {
        didSet {
            self.updateUI()
        }
    }

    var originImages: [Int: UIImage] = [:]

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = ""

        if self.rescanEnabled {
            let rescanBarButton = UIBarButtonItem(
                title: Sqaner.stringProvider[.reshoot],
                style: .plain,
                target: self,
                action: #selector(onRescanButtonTap)
            )
            rescanBarButton.tintColor = Sqaner.tintColor

            self.navigationItem.rightBarButtonItems = [rescanBarButton]
        } else {
            self.navigationItem.rightBarButtonItems = []
        }

        self.imageViewer.pageUpdated = { page in
            self.updateUI()
        }

        let page = self.initialPage <= self.currentItems.count ? self.initialPage : 0
        self.reload(page: page)

        if self.navigationController?.presentingViewController != nil,
           self.navigationController?.viewControllers.count == 1 {
            // pushed
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }

        self.doneButton.setTitle(Sqaner.stringProvider[.done], for: .normal)
        self.doneButton.setTitleColor(Sqaner.tintColor, for: .normal)

        self.closeBarButton.tintColor = Sqaner.tintColor
        self.fillBarButton.tintColor = Sqaner.tintColor
        self.cropBarButton.tintColor = Sqaner.tintColor
        self.rotateBarButton.tintColor = Sqaner.tintColor
        self.enhanceBarButton.tintColor = Sqaner.tintColor
        self.deleteBarButton.tintColor = Sqaner.tintColor
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    func prepare(items: [SqanerItem],
                 initialPage: Int = 0,
                 rescanEnabled: Bool = false,
                 completion: @escaping (_ items: [SqanerItem]) -> Void) {
        self.currentItems = items
        self.initialPage = initialPage
        self.rescanEnabled = rescanEnabled
        self.completion = completion
    }

    private func reload(page: Int = 0) {
        self.imageViewer.update(images: self.currentItems.map({ $0.image }), page: page)
        self.updateUI()
    }

    private func updateUI() {
        if self.imageViewer != nil {
            let page = self.imageViewer.page
            self.navigationItem.title = "\(page + 1) \(Sqaner.stringProvider[.outOf] ?? "") \(self.currentItems.count)"
        }
    }
}

extension PreviewController {
    @objc private func onRescanButtonTap(_ sender: Any) {
        let page = self.imageViewer.page
        let item = self.currentItems[page]

        Sqaner.rescan(item: item, presenter: self) { (resultItem) in
            resultItem.quad = nil
            self.currentItems[page] = resultItem
            self.reload(page: page)
        }
    }

    @IBAction func onEditButtonTap(_ sender: Any) {
        let page = self.imageViewer.page
        let item = self.currentItems[page]

        Sqaner.edit(item: item, presenter: self) { (resultItem) in
            resultItem.quad = nil
            resultItem.isEdited = true
            self.currentItems[page] = resultItem
            self.reload(page: page)
        }
    }

    @IBAction func onCropButtonTap(_ sender: Any) {
        let page = self.imageViewer.page
        let item = self.currentItems[page]

        Sqaner.crop(item: item, presenter: self) { (resultItem) in
            resultItem.isEdited = true
            resultItem.quad = nil
            self.currentItems[page] = resultItem
            self.reload(page: page)
        }
    }

    @IBAction func onRotateButtonTap(_ sender: Any) {
        let page = self.imageViewer.page
        let item = self.currentItems[page]

        DispatchQueue.global(qos: .userInitiated).async {
            if let rotatedImage = item.image.rotate(radians: -.pi/2) {
                let newItem = SqanerItem(index: item.index, image: rotatedImage)
                newItem.meta = item.meta
                newItem.isEdited = true
                newItem.image = rotatedImage

                DispatchQueue.main.async {
                    self.currentItems[page] = newItem
                    self.reload(page: page)
                }
            }
        }
    }

    @IBAction func onEnhanceButtonTap(_ sender: Any) {

        let page = self.imageViewer.page
        let item = self.currentItems[page]

        if let originImage = self.originImages[page] {
            let newItem = SqanerItem(index: item.index, image: originImage)
            newItem.meta = item.meta
            newItem.isEdited = true
            self.currentItems[page] = newItem
            self.reload(page: page)
            self.originImages.removeValue(forKey: page)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let ciImage = CIImage(image: item.image) {
                self.originImages[page] = item.image
                let cgOrientation = CGImagePropertyOrientation(item.image.imageOrientation)
                let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
                let enhancedImage = orientedImage.applyingAdaptiveThreshold() ?? UIImage()
                let newItem = SqanerItem(index: item.index, image: enhancedImage)
                newItem.meta = item.meta
                newItem.isEdited = true

                DispatchQueue.main.async {
                    self.currentItems[page] = newItem
                    self.reload(page: page)
                }
            }
        }
    }

    @IBAction func onDeleteButtonTap(_ sender: Any) {
        var page = self.imageViewer.page
        self.currentItems.remove(at: page)

        if self.currentItems.count > 0 {
            if page > 0 {
                page -= 1
            }
            self.reload(page: page)
        } else {
            dismiss(animated: true) {
            }
        }
    }

    @IBAction func onDoneButtonTap(_ sender: Any) {
        self.completion?(self.currentItems)
        self.dismiss(animated: true)
    }

    @IBAction func onCloseButtonTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(
                    x: -self.size.width/2, y: -self.size.height/2,
                    width: self.size.width, height: self.size.height
        ))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
