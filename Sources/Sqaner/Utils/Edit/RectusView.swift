//
//  RectusView.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/20/20.
//

import UIKit

extension ImageViewerItem {
    @objc func display(image: UIImage, rectusView: RectusView) {
        self.display(image: image)

        if let view = self.zoomImageView {
            view.addSubview(rectusView)

            rectusView.translatesAutoresizingMaskIntoConstraints = false
            rectusView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
            rectusView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
            rectusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
            rectusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        }
    }
}

extension CGRect {
    struct Holder {
        static var fillColor = [String: UIColor]()
    }

    var fillColor: UIColor {
        get {
            return Holder.fillColor[self.debugDescription] ?? .black
        }
        set(newValue) {
            Holder.fillColor[self.debugDescription] = newValue
        }
    }
}

class RectusView: UIView {
    lazy var fillColor: UIColor = .black {
        didSet {
            self.setNeedsDisplay()
        }
    }

    lazy var rectangles: [CGRect] = []
    lazy var undoRectangles: [CGRect] = []

    var didAddNewRectangle: ((_ rect: CGRect) -> Void)?
    var didUndo: ((_ rectangles: [CGRect]) -> Void)?
    var didRedo: ((_ undoRectangles: [CGRect]) -> Void)?

    lazy var tempPointStart = CGPoint(x: 0, y: 0)
    lazy var tempPointEnd = CGPoint(x: 0, y: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.pan))
        self.addGestureRecognizer(panGestureRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        do {
            guard let con = UIGraphicsGetCurrentContext() else { return }
            con.setStrokeColor(UIColor.clear.cgColor)
            con.setFillColor(self.fillColor.cgColor)

            //user is still drawing
            if self.tempPointStart.x != self.tempPointEnd.x || self.tempPointStart.y != self.tempPointEnd.y {
                for rect in self.rectangles {
                    con.addRect(rect)
                    con.setFillColor(rect.fillColor.cgColor)
                    con.fill(rect)
                }

                let rect = CGRect(
                    x: self.tempPointStart.x,
                    y: self.tempPointStart.y,
                    width: self.tempPointEnd.x - self.tempPointStart.x,
                    height: self.tempPointEnd.y - self.tempPointStart.y
                )

                con.addRect(rect)
                con.setFillColor(self.fillColor.cgColor)
                con.fill(rect)
            } else {
                for rect in self.rectangles {
                    con.addRect(rect)
                    con.setFillColor(rect.fillColor.cgColor)
                    con.fill(rect)
                }
            }

            con.strokePath()
        }
    }

    @objc private func pan(_ panGestureRecognizer: UIGestureRecognizer) {
        switch panGestureRecognizer.state {
        case .began:
            self.tempPointStart = panGestureRecognizer.location(in: self)
        case .changed:
            self.tempPointEnd = panGestureRecognizer.location(in: self)
            self.setNeedsDisplay()
        case .ended:
            self.tempPointEnd = panGestureRecognizer.location(in: self)

            var rect = CGRect(
                x: self.tempPointStart.x,
                y: self.tempPointStart.y,
                width: self.tempPointEnd.x-self.tempPointStart.x,
                height: self.tempPointEnd.y-self.tempPointStart.y
            )

            rect.fillColor = self.fillColor

            self.undoRectangles.removeAll()
            self.rectangles.append(rect)
            self.didAddNewRectangle?(rect)

            self.tempPointStart = CGPoint(x: 0, y: 0)
            self.tempPointEnd = CGPoint(x: 0, y: 0)
            self.setNeedsDisplay()
        default: break
        }
    }

    func undo() {
        if let last = self.rectangles.last {
            self.undoRectangles.append(last)
            self.rectangles.removeLast()
            self.didUndo?(self.undoRectangles)
        }
        self.setNeedsDisplay()
    }

    func redo() {
        if let last = self.undoRectangles.last {
            self.rectangles.append(last)
            self.undoRectangles.removeLast()
            self.didRedo?(self.rectangles)
        }
        self.setNeedsDisplay()
    }
}
