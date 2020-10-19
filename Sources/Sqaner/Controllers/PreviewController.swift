//
//  PreviewController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class PreviewController: UIViewController {
    @IBOutlet weak var imageViewer: ImageViewer!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.reload()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    private func reload() {
        self.imageViewer.update(images: Sqaner.sessionItems.map({ $0.resultImage! }))
    }
}

public extension PreviewController {
    @IBAction func onEditButtonTap(_ sender: Any) {
        Sqaner.edit(item: SqanerItem(index: 0, image: UIImage()), presenter: self)
    }
    
    @IBAction func onCropButtonTap(_ sender: Any) {
        Sqaner.crop(item: SqanerItem(index: 0, image: UIImage()), presenter: self)
    }
    
    @IBAction func onRotateButtonTap(_ sender: Any) {
        let page = self.imageViewer.page
        let item = Sqaner.sessionItems[page]
        
        if let image = item.resultImage {
            item.resultImage = image.rotate(radians: -.pi/2)
            self.reload()
        }
    }
    
    @IBAction func onDeleteButtonTap(_ sender: Any) {
    }
    
    @IBAction func onDoneButtonTap(_ sender: Any) {
        self.dismiss(animated: true) {
            
        }
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
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
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
