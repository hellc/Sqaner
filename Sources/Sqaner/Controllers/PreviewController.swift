//
//  PreviewController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

class PreviewController: UIViewController {
    var initialPage: Int = 0
    var rescanEnabled = false
    var completion: ((_ items: [SqanerItem]) -> Void)?

    @IBOutlet weak var imageViewer: ImageViewer!

    var currentItems: [SqanerItem] = [] {
        didSet {
            self.updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = ""

        if self.rescanEnabled {
            let rescanBarButton = UIBarButtonItem(
                title: "Переснять", style: .plain, target: self, action: #selector(onRescanButtonTap)
            )

            self.navigationItem.rightBarButtonItems = [rescanBarButton]
        } else {
            self.navigationItem.rightBarButtonItems = []
        }

        self.imageViewer.pageUpdated = { page in
            self.updateUI()
        }

        let page = self.initialPage <= self.currentItems.count ? self.initialPage : 0
        self.reload(page: page)
    }

    override func viewWillAppear(_ animated: Bool) {
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
        self.imageViewer.update(images: self.currentItems.map({ $0.resultImage! }), page: page)
        self.updateUI()
    }

    private func updateUI() {
        if self.imageViewer != nil {
            let page = self.imageViewer.page
            self.navigationItem.title = "\(page + 1) из \(self.currentItems.count)"
        }
    }
}

extension PreviewController {
    @objc private func onRescanButtonTap(_ sender: Any) {
        let page = self.imageViewer.page
        let item = self.currentItems[page]
        Sqaner.rescan(item: item, presenter: self) { (resultItem) in
            self.currentItems[page] = resultItem
            self.reload(page: page)
        }
    }

    @IBAction func onEditButtonTap(_ sender: Any) {
        let page = self.imageViewer.page
        let item = self.currentItems[page]

        Sqaner.edit(item: item, presenter: self) { (resultItem) in
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
            self.currentItems[page] = resultItem
            self.reload(page: page)
        }
    }

    @IBAction func onRotateButtonTap(_ sender: Any) {
        let page = self.imageViewer.page
        let item = self.currentItems[page]

        if let image = item.resultImage {
            DispatchQueue.global(qos: .userInitiated).async {
                if let rotatedImage = image.rotate(radians: -.pi/2) {
                    let newItem = SqanerItem(index: item.index, image: rotatedImage)
                    newItem.meta = item.meta
                    newItem.isEdited = true
                    newItem.resultImage = rotatedImage

                    DispatchQueue.main.async {
                        self.currentItems[page] = newItem
                        self.reload(page: page)
                    }
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
