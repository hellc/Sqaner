//
//  EditController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class EditController: UIViewController {

    // MARK: Overrided methods

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
}

public extension EditController {
    @IBAction func onCancelButtonTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onDoneButtonTap(_ sender: Any) {
        self.dismiss(animated: true) {

        }
    }

    @IBAction func onPrevButtonTap(_ sender: Any) {
    }

    @IBAction func onNextButtonTap(_ sender: Any) {
    }

    @IBAction func onColorButtonTap(_ sender: Any) {
    }
}
