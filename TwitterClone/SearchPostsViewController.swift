//
//  SearchPostsViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/16.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class SearchPostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var postArray: [PostData] = []
    
    // DatabaseのobserveEventの登録状態を表す
    var searchedPostRefObserving = false
    var allPostRefObserving = false
    
    var previousSearchText = ""
    var postsListSearchedKeys = [[String: String]]()
    var postsListAllKeys = [String]()
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func handleBackButton(_ sender: Any) {
        let navigation = self.storyboard?.instantiateInitialViewController() as! UINavigationController
        self.present(navigation, animated: true, completion: nil)
    }
    
    @IBAction func handleSearchButton(_ sender: Any) {
        // キーボードを閉じる
        self.view.endEditing(true)
        
        if let searchText = searchTextField.text {
            if searchText.isEmpty {
                self.deleteAllPostsWithRemovingObservers()
                self.deleteSearchedPostsWithRemovingObservers()
                self.showAllPosts()
                SVProgressHUD.showError(withStatus: "入力して下さい")
            } else {
                // オブザーバーを削除する
                if self.allPostRefObserving == true {
                    for user_id in self.postsListAllKeys {
                        Database.database().reference().child("posts").child(user_id).removeAllObservers()
                    }
                    self.postsListAllKeys.removeAll()
                    
                    // DatabaseのobserveEventが上記コードにより解除されたため
                    // falseとする
                    self.allPostRefObserving = false
                }
                
                let user = Auth.auth().currentUser
                if let user = user {
                    if (self.searchedPostRefObserving == false) || (searchText != self.previousSearchText) {
                        // オブザーバーを削除する
                        if self.searchedPostRefObserving == true {
                            for refDic in self.postsListSearchedKeys {
                                Database.database().reference().child("posts").child(refDic["userId"]!).child(refDic["postId"]!).removeAllObservers()
                            }
                            self.postsListSearchedKeys.removeAll()
                            
                            // DatabaseのobserveEventが上記コードにより解除されたため
                            // falseとする
                            self.searchedPostRefObserving = false
                        }
                        
                        Database.database().reference().child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
                            self.postArray.removeAll()
                            
                            let posts_list_all = (snapshot.value as? [String: [String: [String: Any]]]) ?? [String: [String: [String: Any]]]() // ここはnullかも
                            
                            for user_id in posts_list_all.keys {
                                let posts_list_each = posts_list_all[user_id]! // ここは必ず存在
                                for post_id in posts_list_each.keys {
                                    let post_each = posts_list_each[post_id]! // ここは必ず存在
                                    let text = (post_each["text"] as? String) ?? ""
                                    
                                    if text.contains(searchText) { // ここで検索している（ここが検索の全て）。改善の余地があるかも。 // 現状だと大文字と小文字を区別
                                        let created_at = (post_each["created_at"] as! Int64) // ここは必ず存在
                                        
                                        Database.database().reference().child("users").child(user_id).observeSingleEvent(of: .value, with: { (snapshotInside) in
                                            let mapInside = snapshotInside.value as! [String: Any] // ここは必ず存在
                                            let iconImageString = mapInside["icon_image"] as! String
                                            let nickname = mapInside["nickname"] as! String
                                            
                                            let refDic = ["userId": user_id, "postId": post_id]
                                            self.postsListSearchedKeys.append(refDic)
                                            Database.database().reference().child("posts").child(user_id).child(post_id).observe(.value, with: { snapshotInsideInside in
                                                let post_each_InsideInside = snapshotInsideInside.value as! [String: Any] // ここは必ず存在
                                                let favoriters_list_InsideInside = (post_each_InsideInside["favoriters_list"] as? [String]) ?? [String]()
                                                let post_id_InsideInside = snapshotInsideInside.key as! String
                                                
                                                // 保持している配列からidが同じものを探す // 存在しないこともある
                                                var index: Int = -1
                                                for post in self.postArray {
                                                    if post.postId == post_id_InsideInside {
                                                        index = self.postArray.firstIndex(of: post)!
                                                        break
                                                    }
                                                }
                                                
                                                if index >= 0 { // 存在すれば入れ替える
                                                    let postDataClassOld = self.postArray[index]
                                                    
                                                    let postDataClassNew = PostData(nickname:postDataClassOld.nickname!,
                                                                                    text:postDataClassOld.text!,
                                                                                    createdAt:postDataClassOld.createdAt!,
                                                                                    favoritersList:favoriters_list_InsideInside,
                                                                                    userId:postDataClassOld.userId!,
                                                                                    postId:postDataClassOld.postId!,
                                                                                    iconImageString:postDataClassOld.iconImageString!,
                                                                                    myId:user.uid)
                                                    
                                                    // 差し替えるため一度削除する
                                                    self.postArray.remove(at: index)
                                                    
                                                    // 削除したところに更新済みのデータを追加する // ここではsortしない
                                                    self.postArray.insert(postDataClassNew, at: index)
                                                    
                                                    // TableViewを再表示する
                                                    self.tableView.reloadData()
                                                } else { // 存在しなければ代入する
                                                    let postDataClass = PostData(nickname:nickname,
                                                                                 text:text,
                                                                                 createdAt:created_at,
                                                                                 favoritersList:favoriters_list_InsideInside,
                                                                                 userId:user_id,
                                                                                 postId:post_id,
                                                                                 iconImageString:iconImageString,
                                                                                 myId:user.uid)
                                                    self.postArray.append(postDataClass)
                                                    
                                                    self.postArray.sort(by: {$0.createdAt! > $1.createdAt!})
                                                    
                                                    // TableViewを再表示する
                                                    self.tableView.reloadData()
                                                }
                                            })
                                        })
                                    }
                                }
                            }
                        })
                        
                        // DatabaseのobserveEventが上記コードにより登録されたため
                        // trueとする
                        self.searchedPostRefObserving = true
                    }
                }
            }
            self.previousSearchText = searchText
        } else {
            self.deleteAllPostsWithRemovingObservers()
            self.deleteSearchedPostsWithRemovingObservers()
            self.showAllPosts()
            SVProgressHUD.showError(withStatus: "入力して下さい")
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
        if let user = user { // 別にログインしている必要性はないが // let postDataClassで必要だった
            self.showAllPosts()
        } else {
            // ログアウトを検出したら、一旦テーブルをクリアしてオブザーバーを削除する。
            self.deleteAllPostsWithRemovingObservers()
            self.deleteSearchedPostsWithRemovingObservers()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // ログアウトを検出したら、一旦テーブルをクリアしてオブザーバーを削除する。
        self.deleteAllPostsWithRemovingObservers()
        self.deleteSearchedPostsWithRemovingObservers()
        
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
    
    private func showAllPosts() {
        let user = Auth.auth().currentUser
        if let user = user { // 別にログインしている必要性はないが // let postDataClassで必要だった
            if self.allPostRefObserving == false {
                Database.database().reference().child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
                    self.postArray.removeAll()
                    
                    let posts_list_all = (snapshot.value as? [String: [String: [String: Any]]]) ?? [String: [String: [String: Any]]]() // ここはnullかも
                    
                    for user_id in posts_list_all.keys {
                        let posts_list_each = posts_list_all[user_id]! // ここは必ず存在
                        
                        Database.database().reference().child("users").child(user_id).observeSingleEvent(of: .value, with: { (snapshotInside) in
                            let mapInside = snapshotInside.value as! [String: Any] // ここは必ず存在
                            let iconImageString = mapInside["icon_image"] as! String
                            let nickname = mapInside["nickname"] as! String
                            
                            for post_id in posts_list_each.keys {
                                let post_each = posts_list_each[post_id]! // ここは必ず存在
                                let text = (post_each["text"] as? String) ?? ""
                                let created_at = (post_each["created_at"] as! Int64) // ここは必ず存在
                                let favoriters_list = (post_each["favoriters_list"] as? [String]) ?? [String]()
                                
                                let postDataClass = PostData(nickname:nickname,
                                                             text:text,
                                                             createdAt:created_at,
                                                             favoritersList:favoriters_list,
                                                             userId:user_id,
                                                             postId:post_id,
                                                             iconImageString:iconImageString,
                                                             myId:user.uid)
                                self.postArray.append(postDataClass)
                                self.postArray.sort(by: {$0.createdAt! > $1.createdAt!})
                                
                                // TableViewを再表示する
                                self.tableView.reloadData()
                            }
                        })
                    }
                    
                    // ここは動作しない予定だが安全のため
                    for user_id in self.postsListAllKeys {
                        print("DEBUG_PRINT: ここは動作しない予定だが安全のため")
                        Database.database().reference().child("posts").child(user_id).removeAllObservers()
                    }
                    self.postsListAllKeys.removeAll()
                    
                    self.postsListAllKeys = [String](posts_list_all.keys) // 参考： https://qiita.com/keisei_1092/items/c9353c91a90c372bbfac
                    
                    for user_id in posts_list_all.keys {
                        Database.database().reference().child("posts").child(user_id).observe(.childChanged, with: { snapshot in
                            let post_each = snapshot.value as! [String: Any] // ここは必ず存在
                            let favoriters_list = (post_each["favoriters_list"] as? [String]) ?? [String]()
                            let post_id = snapshot.key as! String
                            
                            // 保持している配列からidが同じものを探す // 存在しないこともある
                            var index: Int = -1
                            for post in self.postArray {
                                if post.postId == post_id {
                                    index = self.postArray.firstIndex(of: post)!
                                    break
                                }
                            }
                            
                            if index >= 0 { // 存在すれば入れ替える
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
                                
                                // TableViewを再表示する
                                self.tableView.reloadData()
                            }
                        })
                    }
                })
                
                // DatabaseのobserveEventが上記コードにより登録されたため
                // trueとする
                self.allPostRefObserving = true
            }
        }
    }
    
    private func deleteAllPostsWithRemovingObservers() {
        // テーブルをクリアする
        self.postArray.removeAll()
        self.tableView.reloadData()
        
        // オブザーバーを削除する
        if self.allPostRefObserving == true {
            for user_id in self.postsListAllKeys {
                Database.database().reference().child("posts").child(user_id).removeAllObservers()
            }
            self.postsListAllKeys.removeAll()
            
            // DatabaseのobserveEventが上記コードにより解除されたため
            // falseとする
            self.allPostRefObserving = false
        }
    }
    
    private func deleteSearchedPostsWithRemovingObservers() {
        // テーブルをクリアする
        self.postArray.removeAll()
        self.tableView.reloadData()
        
        // オブザーバーを削除する
        if self.searchedPostRefObserving == true {
            for refDic in self.postsListSearchedKeys {
                Database.database().reference().child("posts").child(refDic["userId"]!).child(refDic["postId"]!).removeAllObservers()
            }
            self.postsListSearchedKeys.removeAll()
            
            // DatabaseのobserveEventが上記コードにより解除されたため
            // falseとする
            self.searchedPostRefObserving = false
        }
    }
}
