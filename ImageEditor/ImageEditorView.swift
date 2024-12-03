//
//  ImageEditorView.swift
//  ImageEditor
//
//  Created by 汪更生 on 2024/9/24.
//

import UIKit
import SnapKit
import Kingfisher

public enum ImageEditorAction {
    case save, cancel, rotate
}

public protocol imageEditorDelegate: AnyObject {
    func imageEditor(_ imageEditor: ImageEditorView, action: ImageEditorAction, transform: [String: Double])
}

public class ImageEditorView: UIView {
    private let imageView: UIImageView
    private let overlayView: UIView
    private let saveButton: UIButton
    private let rotateButton: UIButton
    
    private var currentTransform: CGAffineTransform = .identity

    public var image: UIImage? {
        didSet {
            imageView.image = image
            adjustImageToCenterInHole()
            loadTransformData()
        }
    }
    
    private let holeSize: CGSize
    
    public var maskOpacity: CGFloat = 0.5 {
        didSet {
            overlayView.alpha = maskOpacity
        }
    }
    
    public var maskColor: UIColor = .black {
        didSet {
            overlayView.backgroundColor = maskColor
        }
    }
    
    public var borderColor: UIColor = .black {
        didSet {
            outlineLayer.strokeColor = borderColor.cgColor
        }
    }

    public var borderWidth: CGFloat = 2.0 {
        didSet {
            outlineLayer.lineWidth = borderWidth
        }
    }

    private let outlineLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.black.cgColor
        layer.lineWidth = 2.0
        return layer
    }()

    var cutoutFrame: CGRect {
        let x = (bounds.width - holeSize.width) / 2
        let y = (bounds.height - holeSize.height) / 2
        return CGRect(x: x, y: y, width: holeSize.width, height: holeSize.height)
    }
    
    private func updateOutlinePath() {
        let path = UIBezierPath(rect: cutoutFrame)
        outlineLayer.path = path.cgPath
    }
    
    public var gesturesEnabled: Bool = true {
        didSet {
            self.isUserInteractionEnabled = gesturesEnabled
            updateGestureRecognizers()
        }
    }
    
    public var isSupportRotateGesture: Bool = false {
        didSet {
            gestureRecognizers?.forEach{ gesture in
                if let gesture = gesture as? UIRotationGestureRecognizer {
                    gesture.isEnabled = isSupportRotateGesture
                }
            }
        }
    }
    
    private func updateGestureRecognizers() {
        gestureRecognizers?.forEach { gesture in
            if let gesture = gesture as? UIRotationGestureRecognizer {
                gesture.isEnabled = isSupportRotateGesture
            } else {
                gesture.isEnabled = gesturesEnabled
            }
        }
    }

    public var isHiddenSaveButton = true {
        didSet {
            self.saveButton.isHidden = isHiddenSaveButton
        }
    }
    
    public var isHiddenRotateButton = true {
        didSet {
            self.rotateButton.isHidden = isHiddenRotateButton
        }
    }
    
    public weak var delegate: imageEditorDelegate?
    
    public var urlString: String? {
        didSet {
            if let urlString = urlString, let url = URL(string: urlString) {
                
                imageView.kf.indicatorType = .activity
                imageView.kf.setImage(
                    with: url,
                    placeholder: UIImage(named: "kingfisher"), // 占位图
                    options: [
                        .transition(.fade(0.2)), // 淡入效果
                        .cacheOriginalImage // 缓存原始图片
                    ],
                    progressBlock: { receivedSize, totalSize in
                        // 更新下载进度
                        print("Downloading progress: \(receivedSize)/\(totalSize)")
                    },
                    completionHandler: { result in
                        switch result {
                        case .success(let value):
                            // 成功下载并设置图片
                            print("Image set successfully: \(value.image)")
                            self.image = value.image
                            self.adjustImageToCenterInHole()
                        case .failure(let error):
                            // 处理错误
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                )
            }
        }
    }
    
    public override convenience init(frame: CGRect) {
        self.init(frame: frame, visualSize: CGSize(width: 200, height: 200))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public convenience init(frame: CGRect, visualSize: CGSize) {
        self.init(frame: frame, visualSize: visualSize, image: nil, transform: nil)
    }
    
    public init(frame: CGRect, visualSize: CGSize, image: UIImage?, transform: [String: Double]?) {
        imageView = UIImageView()
        overlayView = UIView()
        saveButton = UIButton(type: .system)
        rotateButton = UIButton(type: .system)
        holeSize = visualSize
        
        super.init(frame: frame)

        setupSubviews()
        setupGestureRecognizers()
        
        let downloader = KingfisherManager.shared.downloader
        downloader.downloadTimeout = 60
        
        if let image = image {
            self.image = image
            imageView.image = image
            adjustImageToCenterInHole()
            if let transformDict = transform {
                let transform = CGAffineTransform(
                    a: transformDict["a"] ?? 1,
                    b: transformDict["b"] ?? 0,
                    c: transformDict["c"] ?? 0,
                    d: transformDict["d"] ?? 1,
                    tx: transformDict["tx"] ?? 0,
                    ty: transformDict["ty"] ?? 0
                )
                currentTransform = transform
                imageView.transform = currentTransform
            }
        }
        
        clipsToBounds = true
    }

    private func setupSubviews() {
        addSubview(imageView)
        addSubview(overlayView)
        addSubview(saveButton)
        addSubview(rotateButton)
        layer.addSublayer(outlineLayer)
        
        imageView.backgroundColor = .cyan
        imageView.frame = cutoutFrame
        
        overlayView.backgroundColor = maskColor
        overlayView.isUserInteractionEnabled = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        createHoleInOverlay()
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(100)
            make.trailing.equalToSuperview().offset(-20)
        }
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton.isHidden = isHiddenSaveButton
        
        rotateButton.setTitle("Rotate", for: .normal)
        rotateButton.translatesAutoresizingMaskIntoConstraints = false
        rotateButton.snp.makeConstraints { make in
            make.centerY.equalTo(saveButton)
            make.trailing.equalTo(saveButton.snp.leading).offset(-20)
        }
        rotateButton.addTarget(self, action: #selector(rotateButtonTapped), for: .touchUpInside)
        rotateButton.isHidden = isHiddenRotateButton
    }

    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        addGestureRecognizer(panGesture)
        addGestureRecognizer(pinchGesture)
        addGestureRecognizer(rotationGesture)
    }

    private func createHoleInOverlay() {
        let path = UIBezierPath(rect: overlayView.bounds)
        let holeRect = CGRect(
            x: (overlayView.bounds.width - holeSize.width) / 2,
            y: (overlayView.bounds.height - holeSize.height) / 2,
            width: holeSize.width,
            height: holeSize.height
        )
        path.append(UIBezierPath(rect: holeRect).reversing())
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        overlayView.layer.mask = maskLayer
    }

    private func adjustImageToCenterInHole() {
        guard let imageSize = image?.size else { return }
        let scaleWidth = holeSize.width / imageSize.width
        let scaleHeight = holeSize.height / imageSize.height
        let scale = max(scaleWidth, scaleHeight)

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        // Calculate the center of the cutoutFrame
        let holeCenterX = cutoutFrame.midX
        let holeCenterY = cutoutFrame.midY

        // Calculate correct frame to center the image in the hole
        let xOffset = holeCenterX - (scaledWidth / 2)
        let yOffset = holeCenterY - (scaledHeight / 2)

        // Directly set imageView's frame
        imageView.frame = CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)
        imageView.contentMode = .scaleAspectFill
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        
        let translation = gesture.translation(in: self)
        
        var rotationOnlyTransform = CGAffineTransform(rotationAngle: atan2(currentTransform.b, currentTransform.a))
        rotationOnlyTransform = rotationOnlyTransform.inverted()
        let adjustedTranslation = CGPoint(
            x: translation.x * rotationOnlyTransform.a + translation.y * rotationOnlyTransform.c,
            y: translation.x * rotationOnlyTransform.b + translation.y * rotationOnlyTransform.d
        )
        
        currentTransform = currentTransform.translatedBy(x: adjustedTranslation.x, y: adjustedTranslation.y)
        imageView.transform = currentTransform
        gesture.setTranslation(.zero, in: self)
        
        if gesture.state == .ended {
            adjustImageWithinBounds()
        }
    }
    
    private func adjustImageWithinBounds() {
        // 获取图片在父视图坐标系中的边界
        let transformedFrame = imageView.convert(imageView.bounds, to: self)
        
        var positionAdjustment = CGPoint.zero
        
        // 计算水平调整
        if transformedFrame.width < cutoutFrame.width {
               positionAdjustment.x = cutoutFrame.midX - transformedFrame.midX
        } else {
            if transformedFrame.minX > cutoutFrame.minX {
                positionAdjustment.x = cutoutFrame.minX - transformedFrame.minX
            } else if transformedFrame.maxX < cutoutFrame.maxX {
                positionAdjustment.x = cutoutFrame.maxX - transformedFrame.maxX
            }
        }
        
        // 计算垂直调整
        if transformedFrame.height < cutoutFrame.height {
            positionAdjustment.y = cutoutFrame.midY - transformedFrame.midY
        } else {
            if transformedFrame.minY > cutoutFrame.minY {
                positionAdjustment.y = cutoutFrame.minY - transformedFrame.minY
            } else if transformedFrame.maxY < cutoutFrame.maxY {
                positionAdjustment.y = cutoutFrame.maxY - transformedFrame.maxY
            }
        }
        
        // 获取当前的缩放比例
        let scaleX = sqrt(currentTransform.a * currentTransform.a + currentTransform.c * currentTransform.c)
        let scaleY = sqrt(currentTransform.b * currentTransform.b + currentTransform.d * currentTransform.d)

        // 考虑缩放因素调整平移
        positionAdjustment = CGPoint(
            x: positionAdjustment.x / scaleX,
            y: positionAdjustment.y / scaleY
        )
        
        var rotationOnlyTransform = CGAffineTransform(rotationAngle: atan2(currentTransform.b, currentTransform.a))
        rotationOnlyTransform = rotationOnlyTransform.inverted()
        let adjustedTranslation = CGPoint(
            x: positionAdjustment.x * rotationOnlyTransform.a + positionAdjustment.y * rotationOnlyTransform.c,
            y: positionAdjustment.x * rotationOnlyTransform.b + positionAdjustment.y * rotationOnlyTransform.d
        )

        currentTransform = currentTransform.translatedBy(x: adjustedTranslation.x, y: adjustedTranslation.y)
        UIView.animate(withDuration: 0.25) {
            self.imageView.transform = self.currentTransform
        }

    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            currentTransform = currentTransform.scaledBy(x: gesture.scale, y: gesture.scale)
            imageView.transform = currentTransform
            gesture.scale = 1.0
        }

        if gesture.state == .ended {
            // 获取当前缩放比例
            let currentScaleX = sqrt(currentTransform.a * currentTransform.a + currentTransform.c * currentTransform.c)
            let currentScaleY = sqrt(currentTransform.b * currentTransform.b + currentTransform.d * currentTransform.d)
            
            // 定义最小和最大缩放比例
            let minScale = max(cutoutFrame.width / imageView.bounds.width,
                               cutoutFrame.height / imageView.bounds.height)
            let maxScale = max(bounds.width / (imageView.image?.size.width ?? 1),
                               bounds.height / (imageView.image?.size.height ?? 1))
            
            // 确保缩放在限制范围内
            var scaleAdjustment: CGFloat = 1.0
            if currentScaleX < minScale || currentScaleY < minScale {
                scaleAdjustment = minScale / currentScaleX
            } else if currentScaleX > maxScale || currentScaleY > maxScale {
                scaleAdjustment = maxScale / currentScaleX
            }
            
            // 分别调整x和y方向的缩放
            currentTransform = currentTransform.scaledBy(x: scaleAdjustment, y: scaleAdjustment)
            imageView.transform = currentTransform
            
            adjustImageWithinBounds()
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        currentTransform = currentTransform.rotated(by: gesture.rotation)
        imageView.transform = currentTransform
        gesture.rotation = 0
    }

    @objc private func saveButtonTapped() {
        saveTransformData()
        if let croppedImage = getCroppedImage() {
            // Save or use the cropped image
            print("Cropped Image: \(croppedImage)")
        }
    }

    @objc private func rotateButtonTapped() {
        // 旋转90度（π/2弧度）
        let rotationAngle = CGFloat.pi / 2
        currentTransform = currentTransform.rotated(by: rotationAngle)
        imageView.transform = currentTransform
    }
    
    private func getCroppedImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: holeSize)
        let croppedImage = renderer.image { context in
            let holeOrigin = CGPoint(
                x: (bounds.width - holeSize.width) / 2,
                y: (bounds.height - holeSize.height) / 2
            )
            context.cgContext.translateBy(x: -holeOrigin.x, y: -holeOrigin.y)
            layer.render(in: context.cgContext)
        }
        return croppedImage
    }

    private func saveTransformData() {
        let transformDict: [String: Double] = [
            "a": currentTransform.a,
            "b": currentTransform.b,
            "c": currentTransform.c,
            "d": currentTransform.d,
            "tx": currentTransform.tx,
            "ty": currentTransform.ty
        ]
        UserDefaults.standard.set(transformDict, forKey: "transform")
        if let delegate = delegate {
            delegate.imageEditor(self, action: .save, transform: transformDict)
        }
    }

    private func loadTransformData() {
        if let transformDict = UserDefaults.standard.dictionary(forKey: "transform") as? [String: CGFloat] {
            let transform = CGAffineTransform(
                a: transformDict["a"] ?? 1,
                b: transformDict["b"] ?? 0,
                c: transformDict["c"] ?? 0,
                d: transformDict["d"] ?? 1,
                tx: transformDict["tx"] ?? 0,
                ty: transformDict["ty"] ?? 0
            )
            currentTransform = transform
            imageView.transform = currentTransform
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        createHoleInOverlay()
        updateOutlinePath()
    }
}
