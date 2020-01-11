//
//  RegisteringViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class RegisteringViewController: UIViewController {
    
    var iconImage: UIImage?
    var backgroundImage: UIImage?
    
    @IBOutlet weak var selfIntroductionTextField: UITextField!
    @IBOutlet weak var iconImageAsButton: UIButton!
    @IBOutlet weak var backgroundImageAsButton: UIButton!
    
    @IBAction func handleIconImageButton(_ sender: Any) {
        let imageSelectViewController = storyboard?.instantiateViewController(withIdentifier: "ImageSelect") as! ImageSelectViewController
        imageSelectViewController.modalPresentationStyle = .overFullScreen
        imageSelectViewController.modalTransitionStyle = .crossDissolve
        imageSelectViewController.id = Const.id__iconImage_from_RegisteringView
        self.present(imageSelectViewController, animated: true, completion: nil)
    }
    
    @IBAction func handleBackgroundImageButton(_ sender: Any) {
        let imageSelectViewController = storyboard?.instantiateViewController(withIdentifier: "ImageSelect") as! ImageSelectViewController
        imageSelectViewController.modalPresentationStyle = .overFullScreen
        imageSelectViewController.modalTransitionStyle = .crossDissolve
        imageSelectViewController.id = Const.id__backgroundImage_from_RegisteringView
        self.present(imageSelectViewController, animated: true, completion: nil)
    }
    
    @IBAction func handleRegisterButton(_ sender: Any) {
        // キーボードを閉じる
        self.view.endEditing(true)
        
        if let selfIntroduction = selfIntroductionTextField.text,
            let iconImage = iconImageAsButton.imageView?.image,
            let backgroundImage = backgroundImageAsButton.imageView?.image {
            
            if selfIntroduction.isEmpty {
                SVProgressHUD.showError(withStatus: "必要項目を入力して下さい")
                return
            }
            
            // HUDで処理中を表示
            SVProgressHUD.show()
            
            let user = Auth.auth().currentUser
            if let user = user {
                let userRef = Database.database().reference().child("users").child(user.uid)
                let iconImageCompressed = iconImage.jpegData(compressionQuality: 0.5)
                let backgroundImageCompressed = backgroundImage.jpegData(compressionQuality: 0.5)
                let iconImageString = iconImageCompressed!.base64EncodedString(options: .lineLength64Characters)
                let backgroundImageString = backgroundImageCompressed!.base64EncodedString(options: .lineLength64Characters)
                
                let additionalDic = ["self_introduction": selfIntroduction,
                                     "icon_image": iconImageString,
                                     "background_image": backgroundImageString]
                
                userRef.updateChildValues(additionalDic){ (error, databaseReference) in
                    if let error = error {
                        print("DEBUG_PRINT: " + error.localizedDescription)
                        SVProgressHUD.showError(withStatus: "updateChildValuesに失敗しました。")
                        return
                    }
                    
                    SVProgressHUD.dismiss()
                    
                    // 全てのモーダルを閉じる // 参考：Lesson8.8.3
                    UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            SVProgressHUD.showError(withStatus: "必要項目を入力して下さい(2)")
        }
    }
    
    @IBAction func handleSkipButton(_ sender: Any) {
        // 全てのモーダルを閉じる // 参考：Lesson8.8.3
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let image = self.iconImage {
            self.iconImageAsButton.setImage(image, for: .normal)
        }

        if let image = self.backgroundImage {
            self.backgroundImageAsButton.setImage(image, for: .normal)
        }
    }
}
