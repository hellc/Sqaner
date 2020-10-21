//
//  ViewController.swift
//  SqanerExample
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit
import Sqaner

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onStartScanningTap(_ sender: Any) {
        Sqaner.scan(presenter: self, needPreview: true) { (_) in

        }
    }
}
