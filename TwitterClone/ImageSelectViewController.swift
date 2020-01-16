//
//  ImageSelectViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/11.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit

class ImageSelectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var id = -1
    
    @IBAction func handleLibraryButton(_ sender: Any) {
        print("test0111n01" + String(self.id))
        
        // ライブラリ（カメラロール）を指定してピッカーを開く
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .photoLibrary
            self.present(pickerController, animated: true, completion: nil)
        }
    }
    
    @IBAction func handleCameraButton(_ sender: Any) {
        // カメラを指定してピッカーを開く
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .camera
            self.present(pickerController, animated: true, completion: nil)
        }
    }
    
    @IBAction func handleCancelButton(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.id == -1 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presentingViewController?.beginAppearanceTransition(true, animated: animated) // 参考：https://techblog.recochoku.jp/7215
        presentingViewController?.endAppearanceTransition()
    }
    
    // 写真を撮影/選択したときに呼ばれるメソッド
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if info[.originalImage] != nil {
            // 撮影/選択された画像を取得する
            let image = info[.originalImage] as! UIImage
            
            print("DEBUG_PRINT: image = \(image)")
            
            if self.id == Const.id__iconImage_from_RegisteringView {
                let registeringViewController = self.presentingViewController as! RegisteringViewController
                registeringViewController.iconImage = image
                self.id = -1
                self.dismiss(animated: true, completion: nil)
            } else if self.id == Const.id__backgroundImage_from_RegisteringView {
                let registeringViewController = self.presentingViewController as! RegisteringViewController
                registeringViewController.backgroundImage = image
                self.id = -1
                self.dismiss(animated: true, completion: nil)
            } else if self.id == Const.id__iconImage_from_SettingView {
                let settingViewController = self.presentingViewController as! SettingViewController
                settingViewController.iconImage = image
                self.id = -1
                self.dismiss(animated: true, completion: nil)
            } else if self.id == Const.id__backgroundImage_from_SettingView {
                let settingViewController = self.presentingViewController as! SettingViewController
                settingViewController.backgroundImage = image
                self.id = -1
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // 閉じる
        picker.dismiss(animated: true, completion: nil)
    }
}
