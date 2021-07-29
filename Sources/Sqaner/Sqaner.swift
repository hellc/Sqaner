//
//  Sqaner.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public enum SqanerLocalizationKey: String {
    case outOf
    case interruption
    case focusDocument
    case focusNextPage
    case undo
    case cancel
    case selectColor
    case done
    case reshoot
}

public class Sqaner {
    static var mainStoryboard: UIStoryboard? {
        return UIStoryboard(name: "Sqaner", bundle: Bundle(for: CameraController.classForCoder()))
    }

    public static var stringProvider: [SqanerLocalizationKey: String] = [:]

    public static var tintColor: UIColor = .blue

    static func initStringProvider() {

        if Sqaner.stringProvider.count == 0 {
            Sqaner.stringProvider[.outOf] = "из"
            Sqaner.stringProvider[.interruption] = "Съемка документов недоступна в режиме многозадачности."
            Sqaner.stringProvider[.focusDocument] = "Наведите камеру на документ "
            Sqaner.stringProvider[.focusNextPage] = "Наведите на следующую страницу"
            Sqaner.stringProvider[.undo] = "Отменить"
            Sqaner.stringProvider[.cancel] = "Отмена"
            Sqaner.stringProvider[.selectColor] = "Выбор цвета"
            Sqaner.stringProvider[.done] = "Готово"
            Sqaner.stringProvider[.reshoot] = "Переснять"
        }

    }

    public static func rescan(item: SqanerItem,
                              presenter: UIViewController,
                              completion: @escaping (_ item: SqanerItem) -> Void = { _ in }) {
        guard let storyboard = Sqaner.mainStoryboard,
              let cameraStageVC = storyboard.instantiateViewController(withIdentifier: "cameraStage")
                as? CameraController else { return }

        Sqaner.initStringProvider()

        cameraStageVC.mode = .rescan(item, completion: completion)

        let presentingVC = UINavigationController(rootViewController: cameraStageVC)
        presentingVC.modalPresentationStyle = .fullScreen

        presenter.present(presentingVC, animated: true, completion: nil)
    }

    public static func scan(presenter: UIViewController,
                            needPreview: Bool = true,
                            completion: @escaping (_ items: [SqanerItem]) -> Void = { _ in }) {
        guard let storyboard = Sqaner.mainStoryboard,
              let cameraStageVC = storyboard.instantiateViewController(withIdentifier: "cameraStage")
                as? CameraController else { return }

        Sqaner.initStringProvider()

        let presentingVC = UINavigationController(rootViewController: cameraStageVC)
        presentingVC.modalPresentationStyle = .fullScreen

        if needPreview {
            cameraStageVC.mode = .scan(completion: { (items, page) in
                Sqaner.preview(
                    items: items,
                    page: page,
                    rescanEnabled: true,
                    presenter: cameraStageVC,
                    completion: completion
                )
            })
        } else {
            cameraStageVC.mode = .scan(completion: { (items, _) in
                completion(items)
            })
        }

        presenter.present(presentingVC, animated: true) {
            Sqaner.scanDidShown(cameraStageVC)
        }
    }

    public static func preview(items: [SqanerItem],
                               page: Int = 0,
                               rescanEnabled: Bool = false,
                               presenter: UIViewController,
                               modal: Bool = false,
                               completion: @escaping (_ items: [SqanerItem]) -> Void = { _ in }) {
        guard let storyboard = Sqaner.mainStoryboard,
              let previewStageVC = storyboard.instantiateViewController(withIdentifier: "previewStage")
                as? PreviewController else { return }

        Sqaner.initStringProvider()

        previewStageVC.prepare(items: items, initialPage: page, rescanEnabled: rescanEnabled, completion: completion)

        if modal {
            let presentingVC = UINavigationController(rootViewController: previewStageVC)
            presentingVC.modalPresentationStyle = .fullScreen
            presenter.present(presentingVC, animated: true) {
                Sqaner.previewDidShown(previewStageVC)
            }
        } else if presenter.navigationController != nil {
            presenter.show(previewStageVC, sender: self)
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (_) in
                Sqaner.previewDidShown(previewStageVC)
            }
        }
    }

    public static func edit(item: SqanerItem,
                            presenter: UIViewController,
                            completion: @escaping (_ item: SqanerItem) -> Void = { _ in }) {
        guard let storyboard = Sqaner.mainStoryboard,
              let editStageVC = storyboard.instantiateViewController(withIdentifier: "editStage")
                as? EditController else { return }

        Sqaner.initStringProvider()

        editStageVC.prepare(item: item, completion: completion)

        let presentingVC = UINavigationController(rootViewController: editStageVC)
        presentingVC.modalPresentationStyle = .fullScreen

        presenter.present(presentingVC, animated: true) {
            Sqaner.editDidShown(editStageVC)
        }
    }

    public static func crop(item: SqanerItem,
                            presenter: UIViewController,
                            completion: @escaping (_ item: SqanerItem) -> Void) {

        Sqaner.initStringProvider()

        let cropStageVC = CropController(item: item, completion: completion)

        let presentingVC = UINavigationController(rootViewController: cropStageVC)
        presentingVC.modalPresentationStyle = .fullScreen

        presenter.present(presentingVC, animated: true) {
            Sqaner.cropDidShown(cropStageVC)
        }
    }

    public static var cameraDidStart: (() -> Void) = {}
    public static var cameraDidCancel: (() -> Void) = {}
    public static var cameraDidReshoot: (() -> Void) = {}
    public static var cameraDidShoot: ((_ item: SqanerItem) -> Void) = { _ in }
    public static var cameraDidComplete: ((_ items: [SqanerItem]) -> Void) = { _ in }

    public static var scanDidShown: ((_ controller: UIViewController) -> Void) = { _ in }
    public static var previewDidShown: ((_ controller: UIViewController) -> Void) = { _ in }
    public static var editDidShown: ((_ controller: UIViewController) -> Void) = { _ in }
    public static var cropDidShown: ((_ controller: UIViewController) -> Void) = { _ in }
}
