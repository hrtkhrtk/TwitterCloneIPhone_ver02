//
//  MyPostsViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/16.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class MyPostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var postArray: [PostData] = []
    
    // DatabaseのobserveEventの登録状態を表す
    var postRefObserving = false
    
    var currentUserUid = ""
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func handleBackButton(_ sender: Any) {
        let navigation = self.storyboard?.instantiateInitialViewController() as! UINavigationController
        self.present(navigation, animated: true, completion: nil)
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
            self.currentUserUid = user.uid
            
            self.postArray.removeAll()
            // TableViewを再表示する
            self.tableView.reloadData()
            
            if self.postRefObserving == false {
                Database.database().reference().child("posts").child(user.uid).observe(.childAdded, with: { snapshot in
                    let map = snapshot.value as! [String: Any]
                    let text = (map["text"] as? String) ?? ""
                    let created_at = (map["created_at"] as! Int64) // ここは必ず存在
                    let favoriters_list = (map["favoriters_list"] as? [String]) ?? [String]()
                    let post_id = snapshot.key as! String
                    
                    Database.database().reference().child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshotInside) in
                        let mapInside = snapshotInside.value as! [String: Any] // ここは必ず存在
                        let iconImageString = mapInside["icon_image"] as! String
                        let nickname = mapInside["nickname"] as! String
                        
                        let postDataClass = PostData(nickname:nickname,
                                                     text:text,
                                                     createdAt:created_at,
                                                     favoritersList:favoriters_list,
                                                     userId:user.uid,
                                                     postId:post_id,
                                                     iconImageString:iconImageString,
                                                     myId:user.uid)
                        self.postArray.append(postDataClass)
                        self.postArray.sort(by: {$0.createdAt! > $1.createdAt!})
                        
                        // TableViewを再表示する
                        self.tableView.reloadData()
                    })
                })
                
                // ここのプログラムは、childChangedするのはfavoriters_listだけであると仮定して書かれている
                Database.database().reference().child("posts").child(user.uid).observe(.childChanged, with: { snapshot in
                    let map = snapshot.value as! [String: Any]
                    let favoriters_list = (map["favoriters_list"] as? [String]) ?? [String]()
                    let post_id = snapshot.key as! String
                    
                    // 保持している配列からidが同じものを探す
                    var index: Int = -1
                    for post in self.postArray {
                        if post.postId == post_id {
                            index = self.postArray.firstIndex(of: post)!
                            break
                        }
                    }
                    
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
                    
                    // 削除したところに更新済みのデータを追加する // どのみちsortするが
                    self.postArray.insert(postDataClassNew, at: index)
                    self.postArray.sort(by: {$0.createdAt! > $1.createdAt!})
                    
                    // TableViewを再表示する
                    self.tableView.reloadData()
                })
                
                // DatabaseのobserveEventが上記コードにより登録されたため
                // trueとする
                self.postRefObserving = true
            }
        } else {
            if self.postRefObserving == true {
                // ログアウトを検出したら、一旦テーブルをクリアしてオブザーバーを削除する。
                // テーブルをクリアする
                self.postArray.removeAll()
                self.tableView.reloadData()
                
                // オブザーバーを削除する // これが必要なのか不明
                Database.database().reference().child("posts").child(self.currentUserUid).removeAllObservers()
                
                self.currentUserUid = ""
                
                // DatabaseのobserveEventが上記コードにより解除されたため
                // falseとする
                self.postRefObserving = false
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.postRefObserving == true {
            // viewWillDisappearでテーブルをクリアしてオブザーバーを削除する。
            // テーブルをクリアする
            self.postArray.removeAll()
            self.tableView.reloadData()
            
            // オブザーバーを削除する // これが必要なのか不明
            Database.database().reference().child("posts").child(self.currentUserUid).removeAllObservers()
            
            self.currentUserUid = ""
            
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
