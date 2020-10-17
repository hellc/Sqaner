//
//  CameraController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class CameraController: UIViewController {
    
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
}

// MARK: UIActions

public extension CameraController {
    
    /// <#Description#>
    /// - Parameter sender: <#sender description#>
    @IBAction func onCloseButtonTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// <#Description#>
    /// - Parameter sender: <#sender description#>
    @IBAction func onFlashButtonTap(_ sender: Any) {
    }
    
    /// <#Description#>
    /// - Parameter sender: <#sender description#>
    @IBAction func onReshootButtonTap(_ sender: Any) {
    }
    
    /// <#Description#>
    /// - Parameter sender: <#sender description#>
    @IBAction func onShootButtonTap(_ sender: Any) {
    }
    
    /// <#Description#>
    /// - Parameter sender: <#sender description#>
    @IBAction func onCompleteButtonTap(_ sender: Any) {
        Sqaner.preview(items: [], presenter: self)
    }
    
}
