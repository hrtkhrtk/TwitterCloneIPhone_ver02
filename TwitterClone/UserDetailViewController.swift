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

class UserDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var postArray: [PostData] = []
    
    // DatabaseのobserveEventの登録状態を表す
    var userRefObserving = false
    var postRefObserving = false
    
    var currentUserUidForUserRef = ""
//    var currentUserUidForPostRef = ""
    
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

        tableView.delegate = self
        tableView.dataSource = self
        
        // テーブルセルのタップを無効にする
        tableView.allowsSelection = false
        
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        
        // テーブル行の高さをAutoLayoutで自動調整する
        tableView.rowHeight = UITableView.automaticDimension
        // テーブル行の高さの概算値を設定しておく
        // 高さ概算値 = 90pt
        tableView.estimatedRowHeight = 90
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")
        
        let user = Auth.auth().currentUser
        if let user = user {
            self.currentUserUidForUserRef = user.uid
//            self.currentUserUidForPostRef = user.uid
            
            self.postArray.removeAll()
            // TableViewを再表示する
            self.tableView.reloadData()
            
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
            
            if self.postRefObserving == false {
                Database.database().reference().child("posts").child(self.userData.userId!).observeSingleEvent(of: .value, with: { snapshot in
                    let posts_list = (snapshot.value as? [String: [String: Any]]) ?? [String: [String: Any]]() // ここはnullかも
                    
                    for post_id in posts_list.keys {
                        let post_each = posts_list[post_id]! // ここは必ず存在
                        
                        let text = (post_each["text"] as? String) ?? ""
                        let created_at = (post_each["created_at"] as! Int64) // ここは必ず存在
                        let favoriters_list = (post_each["favoriters_list"] as? [String]) ?? [String]()
                        
                        Database.database().reference().child("users").child(self.userData.userId!).observeSingleEvent(of: .value, with: { snapshotInside in
                            let mapInside = snapshotInside.value as! [String: Any] // ここは必ず存在
                            let iconImageString = mapInside["icon_image"] as! String
                            let nickname = mapInside["nickname"] as! String
                            
                            let postDataClass = PostData(nickname:nickname,
                                                         text:text,
                                                         createdAt:created_at,
                                                         favoritersList:favoriters_list,
                                                         userId:self.userData.userId!,
                                                         postId:post_id,
                                                         iconImageString:iconImageString,
                                                         myId:user.uid)
                            self.postArray.append(postDataClass)
                            self.postArray.sort(by: {$0.createdAt! > $1.createdAt!})
                            
                            // TableViewを再表示する
                            self.tableView.reloadData()
                        })
                    }
                })
                
                // ここのプログラムは、childChangedするのはfavoriters_listだけであると仮定して書かれている
                Database.database().reference().child("posts").child(self.userData.userId!).observe(.childChanged, with: { snapshot in
                    let map = snapshot.value as! [String: Any]
                    let favoriters_list = (map["favoriters_list"] as? [String]) ?? [String]()
                    let post_id = snapshot.key as! String
                    
                    // 保持している配列からidが同じものを探す // 存在しないこともある
                    var index: Int = -1
                    for post in self.postArray {
                        if post.postId == post_id {
                            index = self.postArray.firstIndex(of: post)!
                            break
                        }
                    }
                    
                    if index >= 0 { // 存在すれば入れ替える // 存在しなければ何もしない
                        let postDataClassOld = self.postArray[index]
                        
                        let postDataClassNew = PostData(nickname:postDataClassOld.nickname!,
                                                        text:postDataClassOld.text!,
                                                        createdAt:postDataClassOld.createdAt!,
                                                        favoritersList:favoriters_list,
                                                        userId:postDataClassOld.userId!,
                                                        postId:postDataClassOld.postId!,
                                                        iconImageString:postDataClassOld.iconImageString!,
                                                        myId:user.uid)
                        
                        // 差し替えるため一度削除する
                        self.postArray.remove(at: index)
                        
                        // 削除したところに更新済みのデータを追加する // ここではsortしない
                        self.postArray.insert(postDataClassNew, at: index)
                        //self.postArray.sort(by: {$0.createdAt! > $1.createdAt!})
                        
                        // TableViewを再表示する
                        self.tableView.reloadData()
                    }
                })
                
                // DatabaseのobserveEventが上記コードにより登録されたため
                // trueとする
                self.postRefObserving = true
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
            
            if self.postRefObserving == true {
                // ログアウトを検出したらオブザーバーを削除する。
                
                // オブザーバーを削除する // これが必要なのか不明
                Database.database().reference().child("posts").child(self.userData.userId!).removeAllObservers()
                
//                self.currentUserUidForPostRef = ""
                
                // DatabaseのobserveEventが上記コードにより解除されたため
                // falseとする
                self.postRefObserving = false
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
        
        if self.postRefObserving == true {
            // ログアウトを検出したらオブザーバーを削除する。
            
            // オブザーバーを削除する // これが必要なのか不明
            Database.database().reference().child("posts").child(self.userData.userId!).removeAllObservers()
            
//            self.currentUserUidForPostRef = ""
            
            // DatabaseのobserveEventが上記コードにより解除されたため
            // falseとする
            self.postRefObserving = false
        }

        super.viewWillDisappear(animated)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得してデータを設定する
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostTableViewCell
        cell.setPostData(postArray[indexPath.row])
        
        // セル内のボタンのアクションをソースコードで設定する
        cell.favoriteButton.addTarget(self, action:#selector(handleFavoriteButton(_:forEvent:)), for: .touchUpInside)
        
        return cell
    }
    
    // セル内のボタンがタップされた時に呼ばれるメソッド
    @objc func handleFavoriteButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: FavoriteButtonがタップされました。")
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        
        let user = Auth.auth().currentUser
        if let user = user {
            Database.database().reference().child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                let userData = snapshot.value as! [String: Any] // userDataは必ず存在
                var existingFavoriteList = (userData["favorites_list"] as? [[String: String]]) ?? [[String: String]]()
                
                if postData.isFaved { // 含まれていれば削除
                    // 保持している配列からidが同じものを探す
                    var index: Int = -1
                    for favoriteData in existingFavoriteList {
                        if favoriteData["post_id"] == postData.postId {
                            index = existingFavoriteList.firstIndex(of: favoriteData)!
                            break
                        }
                    }
                    existingFavoriteList.remove(at: index)
                    Database.database().reference().child("users").child(user.uid).child("favorites_list").setValue(existingFavoriteList)
                    
                    Database.database().reference().child("posts").child(postData.userId!).child(postData.postId!).observeSingleEvent(of: .value, with: { (snapshotInside) in
                        let post = snapshotInside.value as! [String: Any] // postは必ず存在
                        var existingFavoritersListInPost = (post["favoriters_list"] as? [String]) ?? [String]()
                        let indexInside = existingFavoritersListInPost.firstIndex(of: user.uid)!
                        existingFavoritersListInPost.remove(at: indexInside)
                        Database.database().reference().child("posts").child(postData.userId!).child(postData.postId!).child("favoriters_list").setValue(existingFavoritersListInPost)
                    })
                } else { // 含まれなければ追加
                    let data:[String: String] = ["user_id": postData.userId!,
                                                 "post_id": postData.postId!]
                    existingFavoriteList.append(data)
                    Database.database().reference().child("users").child(user.uid).child("favorites_list").setValue(existingFavoriteList)
                    
                    Database.database().reference().child("posts").child(postData.userId!).child(postData.postId!).observeSingleEvent(of: .value, with: { (snapshotInside) in
                        let post = snapshotInside.value as! [String: Any] // postは必ず存在
                        var existingFavoritersListInPost = (post["favoriters_list"] as? [String]) ?? [String]()
                        existingFavoritersListInPost.append(user.uid)
                        Database.database().reference().child("posts").child(postData.userId!).child(postData.postId!).child("favoriters_list").setValue(existingFavoritersListInPost)
                    })
                }
            })
        }
    }
}
