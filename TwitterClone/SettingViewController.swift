//
//  SettingViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import SVProgressHUD

class SettingViewController: UIViewController {
    
    var iconImage: UIImage?
    var backgroundImage: UIImage?
    
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var selfIntroductionTextField: UITextField!
    @IBOutlet weak var iconImageAsButton: UIButton!
    @IBOutlet weak var backgroundImageAsButton: UIButton!
    @IBOutlet weak var emailTextLabel: UILabel!
    @IBOutlet weak var idForSearchTextLabel: UILabel!
    @IBOutlet weak var createdAtTextLabel: UILabel!
    @IBOutlet weak var statusTextLabel: UILabel!
    @IBOutlet weak var availableToTextLabel: UILabel!
    
    @IBAction func handleBackButton(_ sender: Any) {
        // 全てのモーダルを閉じる
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handleIconImageButton(_ sender: Any) {
        let imageSelectViewController = storyboard?.instantiateViewController(withIdentifier: "ImageSelect") as! ImageSelectViewController
        imageSelectViewController.modalPresentationStyle = .overFullScreen
        imageSelectViewController.modalTransitionStyle = .crossDissolve
        imageSelectViewController.id = Const.id__iconImage_from_SettingView
        self.present(imageSelectViewController, animated: true, completion: nil)
    }
    
    @IBAction func handleBackgroundImageButton(_ sender: Any) {
        let imageSelectViewController = storyboard?.instantiateViewController(withIdentifier: "ImageSelect") as! ImageSelectViewController
        imageSelectViewController.modalPresentationStyle = .overFullScreen
        imageSelectViewController.modalTransitionStyle = .crossDissolve
        imageSelectViewController.id = Const.id__backgroundImage_from_SettingView
        self.present(imageSelectViewController, animated: true, completion: nil)
    }
    
    @IBAction func handleChangeButton(_ sender: Any) {
        // キーボードを閉じる
        self.view.endEditing(true)
        
        if let nickname = nicknameTextField.text,
            let selfIntroduction = selfIntroductionTextField.text,
            let iconImage = iconImageAsButton.imageView?.image,
            let backgroundImage = backgroundImageAsButton.imageView?.image {
            
            if nickname.isEmpty || selfIntroduction.isEmpty {
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
                
                let dic = ["nickname": nickname,
                           "self_introduction": selfIntroduction,
                           "icon_image": iconImageString,
                           "background_image": backgroundImageString]
                
                userRef.updateChildValues(dic){ (error, databaseReference) in
                    if let error = error {
                        print("DEBUG_PRINT: " + error.localizedDescription)
                        SVProgressHUD.showError(withStatus: "Changeに失敗しました。")
                        return
                    }
                    
                    SVProgressHUD.dismiss()
                }
            }
        } else {
            SVProgressHUD.showError(withStatus: "必要項目を入力して下さい(2)")
        }
    }
    
    @IBAction func handleToPurchasingButton(_ sender: Any) {
        // 画面を表示する
        let purchasingViewController = self.storyboard?.instantiateViewController(withIdentifier: "Purchasing")
        self.present(purchasingViewController!, animated: true, completion: nil)
    }
    
    @IBAction func handleLogoutButton(_ sender: Any) {
        // ログアウトする
        try! Auth.auth().signOut()
        
        self.cancelNotification()
        
        // これが必要か不明
        nicknameTextField.text = ""
        selfIntroductionTextField.text = ""
        emailTextLabel.text = ""
        idForSearchTextLabel.text = ""
        createdAtTextLabel.text = ""
        statusTextLabel.text = ""
        availableToTextLabel.text = ""
        
        // ログイン画面を表示する
        let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "Login")
        self.present(loginViewController!, animated: true, completion: nil)
        // 全てのモーダルを閉じる（ログイン画面を表示する）
        //UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // currentUserがnilならログインしていない
        if Auth.auth().currentUser == nil {
            // ログインしていないときの処理
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "Login")
            self.present(loginViewController!, animated: true, completion: nil)
        }
        
        if let image = self.iconImage {
            self.iconImageAsButton.setImage(image, for: .normal)
        }
        
        if let image = self.backgroundImage {
            self.backgroundImageAsButton.setImage(image, for: .normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // ここはviewDidAppearに書いてもいいかも（たぶんどっちでもいい）
        let user = Auth.auth().currentUser
        if let user = user {
            let userRef = Database.database().reference().child("users").child(user.uid)
            userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                let data = snapshot.value as! [String: Any]
                self.nicknameTextField.text = (data["nickname"]! as! String)
                self.selfIntroductionTextField.text = (data["self_introduction"]! as! String)
                self.emailTextLabel.text = (data["email"]! as! String)
                self.idForSearchTextLabel.text = (data["id_for_search"]! as! String)
                self.statusTextLabel.text = (data["status"]! as! String)
                
                let created_at = data["created_at"]! as! Int64
                self.createdAtTextLabel.text = Const.getDateTime(time:created_at, format:"yyyy/MM/dd")
                
                let available_to = data["available_to"]! as! Int64
                self.availableToTextLabel.text = Const.getDateTime(time:available_to, format:"yyyy/MM/dd")
                
                let icon_image_String = data["icon_image"]! as! String
                if !(icon_image_String.isEmpty) {
                    let icon_image = UIImage(data: Data(base64Encoded: icon_image_String, options: .ignoreUnknownCharacters)!)
                    self.iconImageAsButton.setImage(icon_image, for: .normal)
                }

                let background_image_String = data["background_image"]! as! String
                if !(background_image_String.isEmpty) {
                    let background_image = UIImage(data: Data(base64Encoded: background_image_String, options: .ignoreUnknownCharacters)!)
                    self.backgroundImageAsButton.setImage(background_image, for: .normal)
                }
            }) { (error) in
                SVProgressHUD.showError(withStatus: "Firebaseのエラー")
                print("DEBUG_PRINT: " + error.localizedDescription)
            }
        }
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        //presentingViewController?.beginAppearanceTransition(true, animated: animated) // 参考：https://techblog.recochoku.jp/7215
//        //presentingViewController?.endAppearanceTransition()
//        print(UIApplication.shared.keyWindow?.rootViewController) // test
//        print(UIApplication.shared.keyWindow?.rootViewController?.presentedViewController) // test
//        print(UIApplication.shared.keyWindow?.rootViewController?.presentingViewController) // test
//        UIApplication.shared.keyWindow?.rootViewController?.beginAppearanceTransition(true, animated: animated) // 参考：https://techblog.recochoku.jp/7215
//        UIApplication.shared.keyWindow?.rootViewController?.endAppearanceTransition()
//    }
    
    private func cancelNotification() {
        // ローカル通知をキャンセルする
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [String(0)])
        
        // 未通知のローカル通知一覧をログ出力 // あってもなくてもいい
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
    }
}
