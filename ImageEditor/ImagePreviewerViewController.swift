//
//  ImagePreviewerViewController.swift
//  ImageEditor
//
//  Created by 汪更生 on 2024/11/22.
//

import UIKit

class ImagePreviewerViewController: UIViewController {

    private var imageEditorView: ImageEditorView!
    
    @IBOutlet weak var content: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .green
        
//        if let imageData = try? Data(contentsOf: URL(string:"https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher-6.jpg")!) {
//            let image = UIImage(data: imageData)
//            if let transformDict = UserDefaults.standard.dictionary(forKey: "transform") as? [String: Double] {
//
//                imageEditorView = ImageEditorView(frame: content.bounds, visualSize: CGSize(width: 300,height: 200), image: image, transform: transformDict)
//            }
//        }
        if imageEditorView == nil {
            imageEditorView = ImageEditorView(frame: content.bounds, visualSize: CGSize(width: 300,height: 200))
            imageEditorView.image = UIImage(named: "kingfisher")
        }
        
        imageEditorView.isHiddenSaveButton = true
        imageEditorView.isHiddenRotateButton = true
        imageEditorView.gesturesEnabled = false
        imageEditorView.translatesAutoresizingMaskIntoConstraints = false
        imageEditorView.delegate = nil
        imageEditorView.maskOpacity = 0.3
        imageEditorView.maskColor = .white
        content.addSubview(imageEditorView)
        
        imageEditorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(EditImage(_:)))
        content.addGestureRecognizer(tapGesture)
        

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @objc func EditImage(_ gesture: UITapGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let editVC = storyboard.instantiateViewController(withIdentifier: "imageEditor") as? ViewController {
            self.navigationController?.pushViewController(editVC, animated: true)
        }
    }
}
