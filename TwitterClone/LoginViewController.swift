//
//  LoginViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import UserNotifications

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func handleLoginButton(_ sender: Any) {
        // キーボードを閉じる
        self.view.endEditing(true)
        
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            if email.isEmpty || password.isEmpty {
                SVProgressHUD.showError(withStatus: "必要項目を入力して下さい")
                return
            }
            
            // HUDで処理中を表示
            SVProgressHUD.show()
            
            Auth.auth().signIn(withEmail: email, password: password) { user, error in
                if let error = error {
                    print("DEBUG_PRINT: " + error.localizedDescription)
                    SVProgressHUD.showError(withStatus: "サインインに失敗しました。")
                    return
                }
                print("DEBUG_PRINT: ログインに成功しました。")
                
                let user = Auth.auth().currentUser
                if let user = user {
                    let userRef = Database.database().reference().child("users").child(user.uid)
                    userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        let data = snapshot.value as! [String: Int64]
                        let available_to = data["available_to"]! // ここは必ず存在
                        if (Int64(NSDate().timeIntervalSince1970 * 1000) > available_to) { // iPhoneの時刻をいじられたらたぶんちゃんと機能しない
                            // statusをupdate
                            let statusDic = ["status": String(0)]
                            userRef.updateChildValues(statusDic){ (error, databaseReference) in
                                //何かしても良い
                            }
                        } else {
                            // statusをupdate // 本来は必要ないが、データが整合してなかったときのため
                            let statusDic = ["status": String(1)]
                            userRef.updateChildValues(statusDic){ (error, databaseReference) in
                                //何かしても良い
                            }
                            
                            self.setNotification(time:available_to)
                        }
                    })
                    
                    
                    // HUDを消す
                    SVProgressHUD.dismiss()
                    
                    // 画面を閉じてViewControllerに戻る
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func handleToSignupButton(_ sender: Any) {
        let signupViewController = self.storyboard?.instantiateViewController(withIdentifier: "Signup")
        self.present(signupViewController!, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    private func setNotification(time: Int64) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になる)
        content.title = "サブスクの期限が切れました"
        content.body = "サブスクの期限が切れました"
        content.sound = UNNotificationSound.default
        
        // 参考：https://qiita.com/alpha22jp/items/676dca97ad54b86645e7
        //let dateUnix:NSTimeInterval = floor(time / 1000)
        //let dateUnix:TimeInterval = floor(time / 1000)
        let dateUnix:TimeInterval = TimeInterval(Int64(time / 1000)) // Int()は小数点以下切り捨てでfloorと同じ。
        //let date = NSDate(timeIntervalSince1970: dateUnix)
        let date = Date(timeIntervalSince1970: dateUnix)
        
        // ローカル通知が発動するtrigger（日付マッチ）を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(0), content: content, trigger: trigger)
        
        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "ローカル通知登録 OK")  // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します。
        }
        
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
