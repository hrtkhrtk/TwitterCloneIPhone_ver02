//
//  UserDetailViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class UserDetailViewController: UIViewController {
    
    // DatabaseのobserveEventの登録状態を表す
    var userRefObserving = false
    
    var currentUserUidForUserRef = ""
    var currentUserUidForPostRef = ""
    
    var isUserDataSet = false // setは過去分詞
    
    var isFollowed: Bool = false
    var isMe: Bool = false
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var nicknameTextLabel: UILabel!
    @IBOutlet weak var idForSearchTextLabel: UILabel!
    @IBOutlet weak var selfIntroductionTextLabel: UILabel!
    @IBOutlet weak var createdAtTextLabel: UILabel!
    @IBOutlet weak var followingsNumTextLabel: UILabel!
    @IBOutlet weak var followersNumTextLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var followButton: UIButton!
    
    var userData: UserData!
    
    @IBAction func handleBackButton(_ sender: Any) {
        // 画面を閉じる
        self.dismiss(animated: true, completion: nil)
        
        // 全てのモーダルを閉じる
        //UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handleFollowButton(_ sender: Any) {
        print("DEBUG_PRINT: FollowButtonがタップされました。")
        
        let user = Auth.auth().currentUser
        if let user = user {
            Database.database().reference().child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                let userDataInSnapshot = snapshot.value as! [String: Any] // userDataは必ず存在
                var existingFollowingsList = (userDataInSnapshot["followings_list"] as? [String]) ?? [String]()
                
                if self.isFollowed { // 含まれていれば削除
                    let index = existingFollowingsList.firstIndex(of: self.userData.userId!)!
                    existingFollowingsList.remove(at: index)
                    Database.database().reference().child("users").child(user.uid).child("followings_list").setValue(existingFollowingsList)
                    
                    Database.database().reference().child("users").child(self.userData.userId!).observeSingleEvent(of: .value, with: { (snapshotInside) in
                        let userDataInSnapshotInside = snapshotInside.value as! [String: Any]
                        var existingFollowersList = (userDataInSnapshotInside["followers_list"] as? [String]) ?? [String]()
                        let indexInside = existingFollowersList.firstIndex(of: user.uid)!
                        existingFollowersList.remove(at: indexInside)
                        Database.database().reference().child("users").child(self.userData.userId!).child("followers_list").setValue(existingFollowersList)
                    })
                } else { // 含まれなければ追加
                    existingFollowingsList.append(self.userData.userId!)
                    Database.database().reference().child("users").child(user.uid).child("followings_list").setValue(existingFollowingsList)
                    
                    Database.database().reference().child("users").child(self.userData.userId!).observeSingleEvent(of: .value, with: { (snapshotInside) in
                        let userDataInSnapshotInside = snapshotInside.value as! [String: Any]
                        var existingFollowersList = (userDataInSnapshotInside["followers_list"] as? [String]) ?? [String]()
                        existingFollowersList.append(user.uid)
                        Database.database().reference().child("users").child(self.userData.userId!).child("followers_list").setValue(existingFollowersList)
                    })
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")
        
        let user = Auth.auth().currentUser
        if let user = user {
            self.currentUserUidForUserRef = user.uid
            self.currentUserUidForPostRef = user.uid
            
            self.isMe = false
            if user.uid == self.userData.userId {
                self.isMe = true
            }
            
            if self.isMe {
                self.followButton.isHidden = true
            } else {
                self.followButton.isHidden = false
            }
            
            if self.userRefObserving == false {
                Database.database().reference().child("users").child(user.uid).child("followings_list").observe(.value, with: { snapshot in
                    let followings_list = (snapshot.value as? [String]) ?? [String]()
                    
                    if !(self.isUserDataSet) {
                        // ここはviewDidAppearやviewDidLoadに書いてもいいかも（たぶんどっちでもいい）
                        Database.database().reference().child("users").child(self.userData.userId!).observeSingleEvent(of: .value, with: { (snapshotInside) in
                            let data = snapshotInside.value as! [String: Any]
                            self.nicknameTextLabel.text = (data["nickname"]! as! String)
                            self.idForSearchTextLabel.text = (data["id_for_search"]! as! String)
                            self.selfIntroductionTextLabel.text = (data["self_introduction"]! as! String)
                            
                            let created_at = data["created_at"]! as! Int64
                            self.createdAtTextLabel.text = Const.getDateTime(time:created_at, format:"yyyy/MM/dd")
                            
                            let icon_image_String = data["icon_image"]! as! String
                            if !(icon_image_String.isEmpty) {
                                let icon_image = UIImage(data: Data(base64Encoded: icon_image_String, options: .ignoreUnknownCharacters)!)
                                self.iconImageView.image = icon_image
                            }
                            
                            let background_image_String = data["background_image"]! as! String
                            if !(background_image_String.isEmpty) {
                                let background_image = UIImage(data: Data(base64Encoded: background_image_String, options: .ignoreUnknownCharacters)!)
                                self.backgroundImageView.image = background_image
                            }
                            
                            let followings_list = (data["followings_list"] as? [String]) ?? [String]()
                            let followingsNum = followings_list.count
                            self.followingsNumTextLabel.text = String(followingsNum)
                            
                            let followers_list = (data["followers_list"] as? [String]) ?? [String]()
                            let followersNum = followers_list.count
                            self.followersNumTextLabel.text = String(followersNum)
                        }) { (error) in
                            SVProgressHUD.showError(withStatus: "Firebaseのエラー")
                            print("DEBUG_PRINT: " + error.localizedDescription)
                        }
                        
                        self.isUserDataSet = true
                    }
                    
                    self.isFollowed = false
                    for following in followings_list {
                        if following == self.userData.userId {
                            self.isFollowed = true
                            break
                        }
                    }
                    
                    if self.isFollowed {
                        self.followButton.setTitle("unfollow", for: .normal)
                    } else {
                        self.followButton.setTitle("follow", for: .normal)
                    }
                })
                
                // DatabaseのobserveEventが上記コードにより登録されたため
                // trueとする
                self.userRefObserving = true
            }
        } else {
            if self.userRefObserving == true {
                // ログアウトを検出したらオブザーバーを削除する。
                
                // オブザーバーを削除する // これが必要なのか不明
                Database.database().reference().child("users").child(self.currentUserUidForUserRef).child("followings_list").removeAllObservers()
                
                self.currentUserUidForUserRef = ""
                
                // DatabaseのobserveEventが上記コードにより解除されたため
                // falseとする
                self.userRefObserving = false
            }
            
            // ログインしていないときの処理
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "Login")
            self.present(loginViewController!, animated: true, completion: nil)
        }
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        // currentUserがnilならログインしていない
//        if Auth.auth().currentUser == nil {
//            // ログインしていないときの処理
//            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "Login")
//            self.present(loginViewController!, animated: true, completion: nil)
//        }
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.userRefObserving == true {
            // ログアウトを検出したらオブザーバーを削除する。
            
            // オブザーバーを削除する // これが必要なのか不明
            Database.database().reference().child("users").child(self.currentUserUidForUserRef).child("followings_list").removeAllObservers()
            
            self.currentUserUidForUserRef = ""
            
            // DatabaseのobserveEventが上記コードにより解除されたため
            // falseとする
            self.userRefObserving = false
        }

        super.viewWillDisappear(animated)
    }
    

}
