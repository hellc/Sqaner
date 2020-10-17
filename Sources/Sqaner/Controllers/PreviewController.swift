//
//  PreviewController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class PreviewController: UIViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
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
    }
    
    @IBAction func onDeleteButtonTap(_ sender: Any) {
    }
    
    @IBAction func onDoneButtonTap(_ sender: Any) {
        self.dismiss(animated: true) {
            
        }
    }
}
