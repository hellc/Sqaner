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
    
    public static func camera(items: [SqanerItem] = [], presenter: UIViewController) {
        guard let storyboard = Sqaner.mainStoryboard else { return }
        let cameraStageVC = storyboard.instantiateViewController(withIdentifier: "cameraStage")
        let presentingVC = UINavigationController(rootViewController: cameraStageVC)
        presentingVC.modalPresentationStyle = .fullScreen
        
        presenter.present(presentingVC, animated: true, completion: nil)
    }
    
    public static func preview(items: [SqanerItem], presenter: UIViewController, modal: Bool = false) {
        guard let storyboard = Sqaner.mainStoryboard else { return }
        let previewStageVC = storyboard.instantiateViewController(withIdentifier: "previewStage")
        
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
    
    public static func crop(item: SqanerItem, presenter: UIViewController) {
        guard let storyboard = Sqaner.mainStoryboard else { return }
        let cropStageVC = storyboard.instantiateViewController(withIdentifier: "cropStage")
        
        let presentingVC = UINavigationController(rootViewController: cropStageVC)
        presentingVC.modalPresentationStyle = .fullScreen
        presenter.present(presentingVC, animated: true, completion: nil)
    }
    
    public var cameraDidStart: (() -> Void) = {}
    public var cameraDidCancel: (() -> Void) = {}
    public var cameraDidReshoot: (() -> Void) = {}
    public var cameraDidShoot: ((_ item: SqanerItem) -> Void) = { _ in }
    public var cameraDidComplete: ((_ items: [SqanerItem]) -> Void) = { _ in }
}
