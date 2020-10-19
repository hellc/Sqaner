//
//  Sqaner.swift
//  Sqaner
//
//  Created by Ivan Manov on 10/17/20.
//

import UIKit

public class Sqaner {
    static var mainStoryboard: UIStoryboard? {
        return UIStoryboard(name: "Sqaner", bundle: Bundle(for: CameraController.classForCoder()))
    }
    
    public static func rescan(item: SqanerItem,
                              presenter: UIViewController,
                              completion: @escaping (_ item: SqanerItem) -> Void) {
        guard let storyboard = Sqaner.mainStoryboard,
              let cameraStageVC = storyboard.instantiateViewController(withIdentifier: "cameraStage")
                as? CameraController else { return }
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
        
        let presentingVC = UINavigationController(rootViewController: cameraStageVC)
        presentingVC.modalPresentationStyle = .fullScreen
        
        if needPreview {
            cameraStageVC.mode = .scan(completion: { (items) in
                Sqaner.preview(items: items, rescanEnabled: true, presenter: cameraStageVC)
            })
        } else {
            cameraStageVC.mode = .scan(completion: completion)
        }
        
        presenter.present(presentingVC, animated: true, completion: nil)
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
        
        previewStageVC.currentItems = items
        previewStageVC.initialPage = page
        previewStageVC.rescanEnabled = rescanEnabled
        
        if modal {
            let presentingVC = UINavigationController(rootViewController: previewStageVC)
            presentingVC.modalPresentationStyle = .fullScreen
            presenter.present(presentingVC, animated: true, completion: nil)
        } else if presenter.navigationController != nil {
            presenter.show(previewStageVC, sender: self)
        }
    }
    
    public static func edit(item: SqanerItem, presenter: UIViewController) {
        guard let storyboard = Sqaner.mainStoryboard else { return }
        let editStageVC = storyboard.instantiateViewController(withIdentifier: "editStage")
        
        let presentingVC = UINavigationController(rootViewController: editStageVC)
        presentingVC.modalPresentationStyle = .fullScreen
        presenter.present(presentingVC, animated: true, completion: nil)
    }
    
    public static func crop(item: SqanerItem,
                            presenter: UIViewController,
                            completion: @escaping (_ item: SqanerItem) -> Void) {
        let cropStageVC = CropController(item: item, completion: completion)
        
        let presentingVC = UINavigationController(rootViewController: cropStageVC)
        presentingVC.modalPresentationStyle = .fullScreen
        
        presenter.present(presentingVC, animated: true)
    }
    
    public static var cameraDidStart: (() -> Void) = {}
    public static var cameraDidCancel: (() -> Void) = {}
    public static var cameraDidReshoot: (() -> Void) = {}
    public static var cameraDidShoot: ((_ item: SqanerItem) -> Void) = { _ in }
    public static var cameraDidComplete: ((_ items: [SqanerItem]) -> Void) = { _ in }
}
