//
//  EditController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class EditController: UIViewController {
    private var rectusView: RectusView!

    var defaultColor: UIColor {
        return UIColor(red: 151 / 255, green: 160 / 255, blue: 175 / 255, alpha: 1.0)
    }
    var currentSelectedColor: Int = 2

    @IBOutlet public weak var imageViewerItem: ImageViewerItem!
    @IBOutlet public weak var currentColorView: UIView!

    @IBOutlet public weak var toolbar: UIToolbar!
    @IBOutlet public weak var undoButtonItem: UIBarButtonItem!
    @IBOutlet public weak var redoButtonItem: UIBarButtonItem!
    @IBOutlet public weak var colorButtonItem: UIBarButtonItem!

    private var image: UIImage!
    private var currentItem: SqanerItem! {
        didSet {
            self.image = currentItem.image
        }
    }
    private var completion: ((_ item: SqanerItem) -> Void)?

    func prepare(item: SqanerItem, completion: @escaping (_ item: SqanerItem) -> Void) {
        self.currentItem = item
        self.completion = completion
    }

    // MARK: Overrided methods

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.currentColorView.backgroundColor = self.defaultColor

        self.imageViewerItem.setup()
        self.imageViewerItem.imageContentMode = .aspectFit
        self.imageViewerItem.initialOffset = .center
        self.imageViewerItem.backgroundColor = .clear
        self.imageViewerItem.layer.masksToBounds = true

        self.rectusView = RectusView(frame: CGRect.zero)
        self.rectusView.fillColor = self.defaultColor
        self.imageViewerItem.display(image: self.image, rectusView: self.rectusView)

        self.rectusView.didAddNewRectangle = { _ in
            self.updateUI()
        }

        self.rectusView.didRedo = { _ in
            self.updateUI()
        }

        self.rectusView.didUndo = { _ in
            self.updateUI()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.updateUI()
    }

    private func updateUI() {
        self.redoButtonItem.isEnabled = self.rectusView.undoRectangles.count > 0
        self.undoButtonItem.isEnabled = self.rectusView.rectangles.count > 0
    }

    private func draw(image: UIImage,
                      rectangles: [CGRect],
                      completion: @escaping (_ resultImage: UIImage) -> Void) {
        DispatchQueue.global().async {
            let imageSize = image.size
            let scale: CGFloat = 1

            UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
            image.draw(at: CGPoint.zero)

            if let context = UIGraphicsGetCurrentContext() {
                for rect in rectangles {
                    context.setFillColor(rect.fillColor.cgColor)
                    context.addRect(rect)
                    context.drawPath(using: .fill)
                }
            }

            let resultImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let image = resultImage {
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }
}

extension EditController {
    @IBAction func onCancelButtonTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onDoneButtonTap(_ sender: Any) {
        self.draw(
            image: self.currentItem.image,
            rectangles: self.rectusView.rectangles) { (resultImage) in
            self.currentItem.image = resultImage
            self.completion?(self.currentItem)
            self.dismiss(animated: true)
        }
    }

    @IBAction func onPrevButtonTap(_ sender: Any) {
        self.rectusView.undo()
    }

    @IBAction func onNextButtonTap(_ sender: Any) {
        self.rectusView.redo()
    }

    @IBAction func onColorButtonTap(_ sender: Any) {
        let alert = UIAlertController(style: .actionSheet)

//        alert.addColorPicker(color: self.rectusView.fillColor) { color in
//            currentColor = color
//        }

        alert.addPalleteColorPicker(selected: self.currentSelectedColor) { (color, newIndex) in

            self.currentSelectedColor = newIndex
            self.rectusView.fillColor = color
            self.currentColorView.backgroundColor = color

            alert.dismiss(animated: true)
        }

        alert.addAction(title: "Отмена", style: .cancel) { (_) in
        }

        self.present(alert, animated: true, completion: nil)
    }
}
