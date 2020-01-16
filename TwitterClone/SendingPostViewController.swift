//
//  SendingPostViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class SendingPostViewController: UIViewController {
    
    @IBOutlet weak var postTextField: UITextField!
    
    @IBAction func handleBackButton(_ sender: Any) {
        // 全てのモーダルを閉じる
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handlePostButton(_ sender: Any) {
        // キーボードを閉じる
        self.view.endEditing(true)
        
        if let post = postTextField.text {
            if post.isEmpty {
                SVProgressHUD.showError(withStatus: "正しく入力してください")
                return
            }
            
            // HUDで処理中を表示
            SVProgressHUD.show()
            
            let user = Auth.auth().currentUser
            if let user = user {
                let postRef = Database.database().reference().child("posts").child(user.uid)
                let postDic = ["text": post,
                               "created_at": ServerValue.timestamp()] as [String: Any]
                postRef.childByAutoId().setValue(postDic) { (error, databaseReference) in
                    if let error = error {
                        print("DEBUG_PRINT: " + error.localizedDescription)
                        SVProgressHUD.showError(withStatus: "postに失敗しました。")
                        return
                    }
                    print("DEBUG_PRINT: postに成功しました。")
                    SVProgressHUD.showSuccess(withStatus: "postに成功しました")
                    self.postTextField.text = ""
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // currentUserがnilならログインしていない
        if Auth.auth().currentUser == nil {
            // ログインしていないときの処理
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "Login")
            self.present(loginViewController!, animated: true, completion: nil)
        }
    }
}
