//
//  PreviewController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class PreviewController: UIViewController {
    var initialPage: Int = 0
    var completion: ((_ items: [SqanerItem]) -> Void)?

    @IBOutlet public weak var imageViewer: ImageViewer!
    @IBOutlet weak var titleLabel: UILabel!
    
    var currentItems: [SqanerItem] = [] {
        didSet {
            self.updateUI()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.titleLabel.text = ""

        self.imageViewer.pageUpdated = { _ in
            self.updateUI()
        }

        let page = self.initialPage <= self.currentItems.count ? self.initialPage : 0
        self.reload(page: page)

        if self.navigationController?.presentingViewController != nil,
           self.navigationController?.viewControllers.count == 1 {
            // pushed
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    func prepare(items: [SqanerItem],
                 initialPage: Int = 0,
                 completion: @escaping (_ items: [SqanerItem]) -> Void) {
        self.currentItems = items
        self.initialPage = initialPage
        self.completion = completion
    }

    private func reload(page: Int = 0) {
        self.imageViewer.update(images: self.currentItems.map({ $0.image }), page: page)
        self.updateUI()
    }

    private func updateUI() {
        if self.imageViewer != nil {
            let page = self.imageViewer.page
            self.titleLabel.text = "\(page + 1) из \(self.currentItems.count)"
        }
    }
}

extension PreviewController {
    @IBAction func onRescanButtonTap(_ sender: Any) {
        let page = self.imageViewer.page
        let item = self.currentItems[page]

        Sqaner.rescan(item: item, presenter: self) { (resultItem) in
            resultItem.quad = nil
            self.currentItems[page] = resultItem
            self.reload(page: page)
        }
    }
    
    @IBAction func onDoneButtonTap(_ sender: Any) {
        self.completion?(self.currentItems)
        self.dismiss(animated: true)
    }

    @IBAction func onCloseButtonTap(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
