//
//  ViewController.swift
//  ImageEditor
//
//  Created by 汪更生 on 2024/9/24.
//

import UIKit

class ViewController: UIViewController {
    private var imageEditorView: ImageEditorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
//        if let imageData = try? Data(contentsOf: URL(string:"https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher-6.jpg")!) {
//            let image = UIImage(data: imageData)
//            if let transformDict = UserDefaults.standard.dictionary(forKey: "transform") as? [String: Double] {
//
//                imageEditorView = ImageEditorView(frame: view.bounds, visualSize: CGSize(width: 300,height: 200), image: image, transform: transformDict)
//            }
//        }
        if imageEditorView == nil {
            imageEditorView = ImageEditorView(frame: view.bounds, visualSize: CGSize(width: 300,height: 200))
            imageEditorView.image = UIImage(named: "kingfisher")
        }
        
//        let transformInfo = ["tx": -16.999753621233523, "a": 7.807013175090647e-17, "b": 1.274982007959551, "ty": -2.9749709883599946, "c": -1.274982007959551, "d": 7.807013175090647e-17]
//        imageEditorView = ImageEditorView(frame: view.bounds, visualSize: CGSize(width: 300, height: 200), image: UIImage(named: "kingfisher"), transform: transformInfo)
        imageEditorView.borderColor = .green
        imageEditorView.maskColor = .white
        imageEditorView.maskOpacity = 0.5
//        imageEditorView.isSupportRotateGesture = true
        imageEditorView.isHiddenSaveButton = false
        imageEditorView.isHiddenRotateButton = false
        imageEditorView.gesturesEnabled = true
        imageEditorView.translatesAutoresizingMaskIntoConstraints = false
        imageEditorView.delegate = self
        view.addSubview(imageEditorView)
        
        NSLayoutConstraint.activate([
            imageEditorView.topAnchor.constraint(equalTo: view.topAnchor),
            imageEditorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageEditorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageEditorView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // 设置图片
//        imageEditorView.image = UIImage(named: "kingfisher") // 请替换为实际图片名称
//        imageEditorView.urlString = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher-6.jpg"
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.adjustImagePositionForRotation()
        })
    }
    
    func adjustImagePositionForRotation() {
        guard let imageEditorView = self.imageEditorView else { return }

        // 获取当前设备方向
        let currentOrientation = UIDevice.current.orientation
        let newBounds = self.view.bounds

        // 根据原始 transform 和新尺寸调整 imageView 的 transform
        imageEditorView.transform = computeTransformForNewOrientation(
            originalTransform: imageEditorView.transform,
            newBounds: newBounds,
            orientation: currentOrientation
        )
    }

    func computeTransformForNewOrientation(
        originalTransform: CGAffineTransform,
        newBounds: CGRect,
        orientation: UIDeviceOrientation
    ) -> CGAffineTransform {
        // 这里可以加入复杂逻辑来计算变换，以下是一个简单的示例：
        let scaleX = newBounds.width / view.bounds.width
        let scaleY = newBounds.height / view.bounds.height

        var newTransform = originalTransform
        newTransform = newTransform.scaledBy(x: scaleX, y: scaleY)

        // 旋转逻辑（可以根据需求调整）
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            newTransform = newTransform.rotated(by: .pi / 2)
        }

        return newTransform
    }
}

extension ViewController: imageEditorDelegate {
    func imageEditor(_ imageEditor: ImageEditorView, action: ImageEditorAction, transform: [String : Double]) {
        switch action {
        case .save:
            print(transform)
        case .cancel:
            break
        case .rotate:
            break
        }
    }
    
    
}
