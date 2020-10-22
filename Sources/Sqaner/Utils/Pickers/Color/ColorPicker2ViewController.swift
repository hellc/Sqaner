//
//  PalletePickerViewController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/22/20.
//

import UIKit

class PalletePickerViewController: UIViewController {

    typealias Selection = (_ color: UIColor, _ index: Int) -> Swift.Void

    fileprivate var selection: PalletePickerViewController.Selection?

    @IBOutlet weak var palleteView: UIView!

    @IBOutlet var sharedButtons: [UIButton]!

    @IBAction func onSharedButtonTap(_ sender: UIButton) {
        self.select(at: sender.tag)
        self.selection?(sender.backgroundColor!, sender.tag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let borderColor = UIColor(red: 218/255, green: 218/255, blue: 222/255, alpha: 1.0).cgColor
        self.sharedButtons.forEach { button in
            button.isSelected = false
            button.layer.borderWidth = 0.5
            button.layer.borderColor = borderColor
        }
    }

    func set(selected index: Int, selection: PalletePickerViewController.Selection?) {
        self.selection = selection

        self.select(at: index)
    }

    private func select(at index: Int) {
        self.sharedButtons.forEach { button in
            button.isSelected = false
        }

        if let button = self.sharedButtons.first(where: { $0.tag == index }) {
            button.isSelected = true
        }
    }
}
