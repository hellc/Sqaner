//
//  SqanerItem.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class SqanerItem {
    public let index: UInt
    public var image: UIImage
    public var isEdited: Bool = false
    
    public var quad: Quadrilateral?
    public var cropedImage: UIImage?
    
    public init(index: UInt, image: UIImage) {
        self.index = index
        self.image = image
    }
    
    func crop(completion: @escaping (_ cropedImage: UIImage) -> Void) {
        DispatchQueue.main.async {
            guard let quad = self.quad,
                  let ciImage = CIImage(image: self.image) else {
                    return
            }
            
            let cgOrientation = CGImagePropertyOrientation(self.image.imageOrientation)
            let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
            
            // Cropped Image
            var cartesianScaledQuad = quad.toCartesian(withHeight: self.image.size.height)
            cartesianScaledQuad.reorganize()
            
            let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
                "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
                "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
                "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
            ])
            
            let croppedImage = UIImage.from(ciImage: filteredImage)
            completion(croppedImage)
        }
    }
}
