import UIKit

// swiftlint:disable identifier_name large_tuple

extension UIAlertController {

    /// Add a Color Picker
    ///
    /// - Parameters:
    ///   - color: input color
    ///   - action: for selected color
    func addColorPicker(color: UIColor = .black, selection: ColorPickerViewController.Selection?) {
        let selection: ColorPickerViewController.Selection? = selection
        var color: UIColor = color

        guard let storyboard = Sqaner.mainStoryboard,
              let vc = storyboard.instantiateViewController(withIdentifier: "colorPicker")
                as? ColorPickerViewController else { return }
        set(vc: vc)

        set(title: "Выбор цвета", font: .systemFont(ofSize: 13), color: .gray)

        vc.set(color: color) { new in
            color = new
            selection?(color)
        }
    }

    /// Add a Color Picker
    ///
    /// - Parameters:
    ///   - color: input color
    ///   - action: for selected color
    func addPalleteColorPicker(selected index: Int,
                               selection: PalletePickerViewController.Selection?) {

        guard let storyboard = Sqaner.mainStoryboard,
              let vc = storyboard.instantiateViewController(withIdentifier: "palletePicker")
                as? PalletePickerViewController else { return }
        set(vc: vc)

        set(title: "Выбор цвета", font: .systemFont(ofSize: 13), color: .gray)

        vc.set(selected: index, selection: selection)
    }

    /// Set alert's title, font and color
    ///
    /// - Parameters:
    ///   - title: alert title
    ///   - font: alert title font
    ///   - color: alert title color
    func set(title: String?, font: UIFont, color: UIColor) {
        if title != nil {
            self.title = title
        }
        setTitle(font: font, color: color)
    }

    func setTitle(font: UIFont, color: UIColor) {
        guard let title = self.title else { return }
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attributedTitle = NSMutableAttributedString(string: title, attributes: attributes)
        setValue(attributedTitle, forKey: "attributedTitle")
    }

    /// Set alert's content viewController
    ///
    /// - Parameters:
    ///   - vc: ViewController
    ///   - height: height of content viewController
    func set(vc: UIViewController?, width: CGFloat? = nil, height: CGFloat? = nil) {
        guard let vc = vc else { return }
        setValue(vc, forKey: "contentViewController")
        if let height = height {
            vc.preferredContentSize.height = height
            preferredContentSize.height = height
        }
    }

    /// Add an action to Alert
    ///
    /// - Parameters:
    ///   - title: action title
    ///   - style: action style (default is UIAlertActionStyle.default)
    ///   - isEnabled: isEnabled status for action (default is true)
    ///   - handler: optional action handler to be called when button is tapped (default is nil)
    func addAction(image: UIImage? = nil,
                   title: String, color: UIColor? = nil,
                   style: UIAlertAction.Style = .default,
                   isEnabled: Bool = true,
                   handler: ((UIAlertAction) -> Void)? = nil) {
        let action = UIAlertAction(title: title, style: style, handler: handler)
        action.isEnabled = isEnabled

        // button image
        if let image = image {
            action.setValue(image, forKey: "image")
        }

        // button title color
        if let color = color {
            action.setValue(color, forKey: "titleTextColor")
        }

        addAction(action)
    }

    /// Present alert view controller in the current view controller.
    ///
    /// - Parameters:
    ///   - animated: set true to animate presentation of alert controller (default is true).
    ///   - vibrate: set true to vibrate the device while presenting the alert (default is false).
    ///   - completion: an optional completion handler to be called after presenting alert controller (default is nil).
    func show(animated: Bool = true,
                     vibrate: Bool = false,
                     style: UIBlurEffect.Style? = nil,
                     completion: (() -> Void)? = nil) {
        if let style = style {
            for subview in view.allSubViewsOf(type: UIVisualEffectView.self) {
                subview.effect = UIBlurEffect(style: style)
            }
        }

        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?.present(
                self, animated: animated, completion: completion
            )
        }
    }

    /// Create new alert view controller.
    ///
    /// - Parameters:
    ///   - style: alert controller's style.
    ///   - title: alert controller's title.
    ///   - message: alert controller's message (default is nil).
    ///   - defaultActionButtonTitle: default action button title (default is "OK")
    ///   - tintColor: alert controller's tint color (default is nil)
    convenience init(style: UIAlertController.Style,
                     source: UIView? = nil,
                     title: String? = nil,
                     message: String? = nil,
                     tintColor: UIColor? = nil) {
        self.init(title: title, message: message, preferredStyle: style)

        let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
        let root = UIApplication.shared.keyWindow?.rootViewController?.view

        //self.responds(to: #selector(getter: popoverPresentationController))
        if let source = source {
            popoverPresentationController?.sourceView = source
            popoverPresentationController?.sourceRect = source.bounds
        } else if isPad, let source = root, style == .actionSheet {
            popoverPresentationController?.sourceView = source
            popoverPresentationController?.sourceRect =
                CGRect(x: source.bounds.midX, y: source.bounds.midY, width: 0, height: 0)
            //popoverPresentationController?.permittedArrowDirections = .down
            popoverPresentationController?.permittedArrowDirections = .init(rawValue: 0)
        }

        if let color = tintColor {
            self.view.tintColor = color
        }
    }
}

extension UIView {
    /// This is the function to get subViews of a view of a particular type
    /// https://stackoverflow.com/a/45297466/5321670
    func subViews<T: UIView>(type: T.Type) -> [T] {
        var all = [T]()
        for view in self.subviews {
            if let aView = view as? T {
                all.append(aView)
            }
        }
        return all
    }

    /// This is a function to get subViews of a particular type from view recursively.
    ///  It would look recursively in all subviews and return back the subviews of the type T
    /// https://stackoverflow.com/a/45297466/5321670
    func allSubViewsOf<T: UIView>(type: T.Type) -> [T] {
        var all = [T]()
        func getSubview(view: UIView) {
            if let aView = view as? T {
                all.append(aView)
            }
            guard view.subviews.count>0 else { return }
            view.subviews.forEach { getSubview(view: $0) }
        }
        getSubview(view: self)
        return all
    }
}

class ColorPickerViewController: UIViewController {

    typealias Selection = (UIColor) -> Swift.Void

    fileprivate var selection: Selection?

    @IBOutlet weak var colorView: UIView!

    @IBOutlet weak var saturationSlider: GradientSlider!
    @IBOutlet weak var brightnessSlider: GradientSlider!
    @IBOutlet weak var hueSlider: GradientSlider!

    @IBOutlet weak var mainStackView: UIStackView!

    var color: UIColor {
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

    var hue: CGFloat = 0.5
    var saturation: CGFloat = 0.5
    var brightness: CGFloat = 0.5
    var alpha: CGFloat = 1

    fileprivate var preferredHeight: CGFloat = 0

    func set(color: UIColor, selection: Selection?) {
        let components = color.hsbaComponents

        hue = components.hue
        saturation = components.saturation
        brightness = components.brightness
        alpha = components.alpha

        let mainColor: UIColor = UIColor(
            hue: hue,
            saturation: 1.0,
            brightness: 1.0,
            alpha: 1.0)

        hueSlider.minColor = mainColor
        hueSlider.thumbColor = mainColor
        brightnessSlider.maxColor = mainColor
        saturationSlider.maxColor = mainColor

        hueSlider.value = hue
        saturationSlider.value = saturation
        brightnessSlider.value = brightness

        updateColorView()

        self.selection = selection
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        saturationSlider.minColor = .white
        brightnessSlider.minColor = .black
        hueSlider.hasRainbow = true

        hueSlider.actionBlock = { [unowned self] slider, newValue in
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)

            self.hue = newValue
            let mainColor: UIColor = UIColor(
                hue: newValue,
                saturation: 1.0,
                brightness: 1.0,
                alpha: 1.0)

            self.hueSlider.thumbColor = mainColor
            self.brightnessSlider.maxColor = mainColor
            self.saturationSlider.maxColor = mainColor

            self.updateColorView()

            CATransaction.commit()
        }

        brightnessSlider.actionBlock = { [unowned self] slider, newValue in
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)

            self.brightness = newValue
            self.updateColorView()

            CATransaction.commit()
        }

        saturationSlider.actionBlock = { [unowned self] slider, newValue in
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)

            self.saturation = newValue
            self.updateColorView()

            CATransaction.commit()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredHeight = mainStackView.frame.maxY
    }

    func updateColorView() {
        colorView.backgroundColor = color
        selection?(color)
    }
}

extension UIColor {

    /// SwifterSwift: https://github.com/SwifterSwift/SwifterSwift
    /// Hexadecimal value string (read-only).
    var hexString: String {
        let components: [Int] = {
            let c = cgColor.components!
            let components = c.count == 4 ? c : [c[0], c[0], c[0], c[1]]
            return components.map { Int($0 * 255.0) }
        }()
        return String(format: "#%02X%02X%02X", components[0], components[1], components[2])
    }

    /// SwifterSwift: https://github.com/SwifterSwift/SwifterSwift
    /// Get components of hue, saturation, and brightness, and alpha (read-only).
    var hsbaComponents: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0

        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (hue: h, saturation: s, brightness: b, alpha: a)
    }

}
