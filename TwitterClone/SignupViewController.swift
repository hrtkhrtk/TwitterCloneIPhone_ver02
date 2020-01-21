//
//  SignupViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import UserNotifications

class SignupViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var idForSearchTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordConfirmationTextField: UITextField!
    
    @IBAction func handleSignupButton(_ sender: Any) {
        // キーボードを閉じる
        self.view.endEditing(true)
        
        if let email = emailTextField.text,
            let nickname = nicknameTextField.text,
            let idForSearch = idForSearchTextField.text,
            let password = passwordTextField.text,
            let passwordConfirmation = passwordConfirmationTextField.text {
            
            if email.isEmpty || nickname.isEmpty || idForSearch.isEmpty || password.isEmpty || passwordConfirmation.isEmpty {
                SVProgressHUD.showError(withStatus: "必要項目を入力して下さい")
                return
            }
            
            if password != passwordConfirmation {
                SVProgressHUD.showError(withStatus: "passwordが一致しません")
                return
            }
            
            Database.database().reference().child("id_for_search_list").observeSingleEvent(of: .value, with: { (snapshot) in
                let data = (snapshot.value as? [String: String]) ?? [String: String]() // ここは存在するとみなしていいと思うが安全のため
                if data.keys.contains(idForSearch) { // 含まれていれば
                    SVProgressHUD.showError(withStatus: "そのidは使われています")
                    return
                }
                
                self.signup(email: email, nickname: nickname, idForSearch: idForSearch, password: password)
                
            }) { (error) in
                SVProgressHUD.showError(withStatus: "Firebaseのエラー")
                print("DEBUG_PRINT: " + error.localizedDescription)
            }
        }
    }
    
    @IBAction func handleBackButton(_ sender: Any) {
        // 画面を閉じてLoginViewControllerに戻る
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func signup(email: String, nickname: String, idForSearch: String, password: String) {
        // HUDで処理中を表示
        SVProgressHUD.show()
    
        // アドレスとパスワードでユーザー作成。ユーザー作成に成功すると、自動的にログインする
        Auth.auth().createUser(withEmail: email, password: password) { user, error in
            if let error = error {
                // エラーがあったら原因をprintして、returnすることで以降の処理を実行せずに処理を終了する
                print("DEBUG_PRINT: " + error.localizedDescription)
                SVProgressHUD.showError(withStatus: "ユーザー作成に失敗しました。")
                return
            }
            print("DEBUG_PRINT: ユーザー作成に成功しました。")
            
            // 表示名を設定する
            let user = Auth.auth().currentUser
            if let user = user {
                let userRef = Database.database().reference().child("users").child(user.uid)
                let status = String(1) // 0:お試しユーザー、1:サブスクユーザー // 最初に一定期間（5日間）のサブスクユーザーとしての地位を与える
                let userDic = ["email": email,
                               "nickname": nickname,
                               "id_for_search": idForSearch,
                               "created_at": ServerValue.timestamp(),
                               "status": status,
                               "self_introduction": "",
                               "icon_image": "",
                               "background_image": "",
                               "available_to": Int64(0)] as [String: Any]
                userRef.setValue(userDic) { (error, databaseReference) in
                    if let error = error {
                        print("DEBUG_PRINT: " + error.localizedDescription)
                        SVProgressHUD.showError(withStatus: "setValueに失敗しました。")
                        return
                    }
                    print("DEBUG_PRINT: setValueに成功しました。")
                    userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        let dataInListener = snapshot.value as! [String: Any]
                        let created_at_InListener = (dataInListener["created_at"] as? Int64) ?? (Int64(-1)) // (-1)の値に意味はない
                        
                        var available_to = Int64(-1) // (-1)の値に意味はない
                        if created_at_InListener >= 0 {
                            let total_day:Int64 = Int64(created_at_InListener / (24*60*60*1000)) // Int()は小数点以下切り捨てでfloorと同じ。
                            available_to = ((total_day + 6) * (24*60*60*1000) - 1000) // 5日後の23時59分59秒
                        }
                        
                        let data_to_update_InListener = ["available_to": available_to]
                        userRef.updateChildValues(data_to_update_InListener){ (error, databaseReference) in
                            if let error = error {
                                print("DEBUG_PRINT: " + error.localizedDescription)
                                SVProgressHUD.showError(withStatus: "available_toのupdateChildValuesに失敗しました。")
                                return
                            }
                            
                            if available_to >= 0 {
                                self.setNotification(time:available_to)
                                print("DEBUG_PRINT: signupに成功しました。")
                            } else {
                                print("available_to < 0 です。")
                            }
                        }
                    }) { (error) in
                        SVProgressHUD.showError(withStatus: "Firebaseのエラー")
                        print("DEBUG_PRINT: " + error.localizedDescription)
                    }
                }
                
                let idForSearchListRef = Database.database().reference().child("id_for_search_list").child(idForSearch)
                let userIdDic = ["user_id": user.uid]
                idForSearchListRef.setValue(userIdDic) { (error, databaseReference) in
                    if let error = error {
                        print("DEBUG_PRINT: " + error.localizedDescription)
                        SVProgressHUD.showError(withStatus: "idForSearchListRefのsetValueに失敗しました。")
                        return // returnするのが適切かは知らんが
                    }
                    
                    SVProgressHUD.dismiss()
                    
                    let registeringViewController = self.storyboard?.instantiateViewController(withIdentifier: "Registering")
                    self.present(registeringViewController!, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func setNotification(time: Int64) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になる)
        content.title = "サブスクの期限が切れました"
        content.body = "サブスクの期限が切れました"
        content.sound = UNNotificationSound.default
        
        // 参考：https://qiita.com/alpha22jp/items/676dca97ad54b86645e7
        let dateUnix:TimeInterval = TimeInterval(Int64(time / 1000)) // Int()は小数点以下切り捨てでfloorと同じ。
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
