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
    
    public init(index: UInt, image: UIImage) {
        self.index = index
        self.image = image
    }
}
