//
//  SqanerItem.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class SqanerItem {
    public var meta: String?

    public let index: UInt
    public var rawImage: UIImage
    public var isEdited: Bool = false

    var quad: Quadrilateral?
    public var resultImage: UIImage?

    public init(index: UInt, image: UIImage) {
        self.index = index
        self.rawImage = image
    }

    func crop(completion: @escaping (_ cropedImage: UIImage) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let quad = self.quad,
                  let ciImage = CIImage(image: self.rawImage) else {
                    return
            }

            let cgOrientation = CGImagePropertyOrientation(self.rawImage.imageOrientation)
            let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))

            // Cropped Image
            var cartesianScaledQuad = quad.toCartesian(withHeight: self.rawImage.size.height)
            cartesianScaledQuad.reorganize()

            let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
                "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
                "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
                "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
            ])

            let croppedImage = UIImage.from(ciImage: filteredImage)

            DispatchQueue.main.async {
                completion(croppedImage)
            }
        }
    }
}
