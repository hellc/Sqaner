//
//  CropController.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit
import AVFoundation

final class ZoomGestureController {
    private let image: UIImage
    private let quadView: QuadrilateralView
    private var previousPanPosition: CGPoint?
    private var closestCorner: CornerPosition?

    init(image: UIImage, quadView: QuadrilateralView) {
        self.image = image
        self.quadView = quadView
    }

    @objc func handle(pan: UIGestureRecognizer) {
        guard let drawnQuad = self.quadView.quad else {
            return
        }

        guard pan.state != .ended else {
            self.previousPanPosition = nil
            self.closestCorner = nil
            self.quadView.resetHighlightedCornerViews()
            return
        }

        let position = pan.location(in: self.quadView)

        let previousPanPosition = self.previousPanPosition ?? position
        let closestCorner = self.closestCorner ?? position.closestCornerFrom(quad: drawnQuad)

        let offset = CGAffineTransform(
            translationX: position.x - previousPanPosition.x, y: position.y - previousPanPosition.y
        )
        let cornerView = self.quadView.cornerViewForCornerPosition(position: closestCorner)
        let draggedCornerViewCenter = cornerView.center.applying(offset)

        self.quadView.moveCorner(cornerView: cornerView, atPoint: draggedCornerViewCenter)

        self.previousPanPosition = position
        self.closestCorner = closestCorner

        let scale = self.image.size.width / self.quadView.bounds.size.width
        let scaledDraggedCornerViewCenter = CGPoint(
            x: draggedCornerViewCenter.x * scale, y: draggedCornerViewCenter.y * scale
        )
        guard let zoomedImage = self.image.scaledImage(
            atPoint: scaledDraggedCornerViewCenter, scaleFactor: 2.5,
            targetSize: self.quadView.bounds.size
        ) else {
            return
        }

        self.quadView.highlightCornerAtPosition(position: closestCorner, with: zoomedImage)
    }
}

final class CropController: UIViewController {
    private var currentItem: SqanerItem!
    private var completion: ((_ item: SqanerItem) -> Void)?

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isOpaque = true
        imageView.image = image
        imageView.backgroundColor = UIColor(red: 218/255, green: 218/255, blue: 222/255, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var quadView: QuadrilateralView = {
        let quadView = QuadrilateralView()
        quadView.editable = true
        quadView.translatesAutoresizingMaskIntoConstraints = false
        return quadView
    }()

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: "Готово", style: .done, target: self, action: #selector(self.onDoneButtonTap)
        )
        button.tintColor = navigationController?.navigationBar.tintColor
        return button
    }()

    private lazy var cancelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: "Отмена", style: .plain, target: self, action: #selector(self.onCancelButtonTap)
        )
        button.tintColor = navigationController?.navigationBar.tintColor
        return button
    }()

    /// The image the quadrilateral was detected on.
    private let image: UIImage

    /// The detected quadrilateral that can be edited by the user. Uses the image's coordinates.
    private var quad: Quadrilateral

    private var zoomGestureController: ZoomGestureController!

    private var quadViewWidthConstraint = NSLayoutConstraint()
    private var quadViewHeightConstraint = NSLayoutConstraint()

    // MARK: - Life Cycle

    init(item: SqanerItem, completion: @escaping (_ item: SqanerItem) -> Void) {
        self.currentItem = item
        self.completion = completion
        self.image = item.image
        self.quad = CropController.defaultQuad(forImage: self.image)
        //item.quad ?? CropController.defaultQuad(forImage: item.image)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(red: 218/255, green: 218/255, blue: 222/255, alpha: 1.0)

        setupViews()
        setupConstraints()

        self.toolbarItems = [
            cancelButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            nextButton
        ]

        zoomGestureController = ZoomGestureController(image: image, quadView: quadView)

        let touchDown = UILongPressGestureRecognizer(
            target: zoomGestureController, action: #selector(zoomGestureController.handle(pan:))
        )
        touchDown.minimumPressDuration = 0
        view.addGestureRecognizer(touchDown)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.isToolbarHidden = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustQuadViewConstraints()
        displayQuad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        /// Work around for an iOS 11.2 bug where UIBarButtonItems don't
        /// get back to their normal state after being pressed.
        navigationController?.navigationBar.tintAdjustmentMode = .normal
        navigationController?.navigationBar.tintAdjustmentMode = .automatic
    }

    private func proceedCrop() {
        guard let quad = self.quadView.quad else { return }

        let scaledQuad = quad.scale(quadView.bounds.size, self.image.size)

        self.currentItem.quad = scaledQuad
        self.currentItem.crop { (image) in
            self.currentItem.image = image
            self.currentItem.quad = nil

            self.completion?(self.currentItem)
            self.dismiss(animated: true)
        }
    }

    // MARK: - Setups

    private func setupViews() {
        view.addSubview(imageView)
        view.addSubview(quadView)
    }

    private func setupConstraints() {
        let imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ]

        quadViewWidthConstraint = quadView.widthAnchor.constraint(equalToConstant: 0.0)
        quadViewHeightConstraint = quadView.heightAnchor.constraint(equalToConstant: 0.0)

        let quadViewConstraints = [
            quadView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quadView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            quadViewWidthConstraint,
            quadViewHeightConstraint
        ]

        NSLayoutConstraint.activate(quadViewConstraints + imageViewConstraints)
    }

    // MARK: - Actions

    @objc func onCancelButtonTap() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func onDoneButtonTap() {
        self.proceedCrop()
    }

    private func displayQuad() {
        let imageSize = image.size
        let imageFrame = CGRect(
            origin: quadView.frame.origin,
            size: CGSize(width: quadViewWidthConstraint.constant,
                         height: quadViewHeightConstraint.constant)
        )

        let scaleTransform = CGAffineTransform.scaleTransform(
            forSize: imageSize, aspectFillInSize: imageFrame.size
        )
        let transforms = [scaleTransform]
        let transformedQuad = quad.applyTransforms(transforms)

        quadView.drawQuadrilateral(quad: transformedQuad, animated: false)
    }

    /// The quadView should be lined up on top of the actual image displayed by the imageView.
    /// Since there is no way to know the size of that image before run time,
    /// we adjust the constraints to make sure that the quadView is on top of the displayed image.
    private func adjustQuadViewConstraints() {
        let frame = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        quadViewWidthConstraint.constant = frame.size.width
        quadViewHeightConstraint.constant = frame.size.height
    }

    /// Generates a `Quadrilateral` object that's centered and 90% of the size of the passed in image.
    private static func defaultQuad(forImage image: UIImage) -> Quadrilateral {
        let topLeft = CGPoint(x: image.size.width * 0.05, y: image.size.height * 0.05)
        let topRight = CGPoint(x: image.size.width * 0.95, y: image.size.height * 0.05)
        let bottomRight = CGPoint(x: image.size.width * 0.95, y: image.size.height * 0.95)
        let bottomLeft = CGPoint(x: image.size.width * 0.05, y: image.size.height * 0.95)

        let quad = Quadrilateral(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)

        return quad
    }

}
