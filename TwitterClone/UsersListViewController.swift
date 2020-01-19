//
//  UsersListViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class UsersListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var userArray: [UserData] = []
    
    // DatabaseのobserveEventの登録状態を表す
    var searchedUserRefObserving = false
    var allUserRefObserving = false
    
    var currentUserUid = ""
    var previousSearchText = ""
    
    // 一度setされたら、この両者が共にfalse/共にtrueとなることはない。
//    var isSearchedUsersDataSet = false // setは過去分詞
    var isAllUsersDataSet = false // setは過去分詞
    
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
                self.deleteAllUsersWithRemovingObservers()
                self.deleteSearchedUsersWithRemovingObservers()
                self.showAllUsers()
                SVProgressHUD.showError(withStatus: "入力して下さい")
            } else {
                //self.deleteSearchedUsersWithRemovingObservers()
                //self.deleteAllUsersWithRemovingObservers()
                
                // オブザーバーを削除する
                if self.allUserRefObserving == true {
                    Database.database().reference().child("users").child(self.currentUserUid).child("followings_list").removeAllObservers()
                    
                    // DatabaseのobserveEventが上記コードにより解除されたため
                    // falseとする
                    self.allUserRefObserving = false
                }
                
                let user = Auth.auth().currentUser
                if let user = user {
                    self.currentUserUid = user.uid
                    
                    if (self.searchedUserRefObserving == false) || (searchText != self.previousSearchText) {
                    //if self.searchedUserRefObserving == false { // これでいいか不明 // よくないっぽい
                        //self.deleteSearchedUsersWithRemovingObservers() // これでいいか不明
                        
                        // オブザーバーを削除する
                        if self.searchedUserRefObserving == true {
                            Database.database().reference().child("users").child(self.currentUserUid).child("followings_list").removeAllObservers()
                            
                            // DatabaseのobserveEventが上記コードにより解除されたため
                            // falseとする
                            self.searchedUserRefObserving = false // どのみちすぐ後ろでtrueにするので、あってもなくても良い
                        }
                        
                        Database.database().reference().child("users").child(user.uid).child("followings_list").observe(.value, with: { (snapshot) in
                            let followings_list = (snapshot.value as? [String]) ?? [String]()
                            
//                            if (self.isSearchedUsersDataSet) && (searchText == self.previousSearchText) {
//                                print("test 2回同じ検索ならここ")
//                                for (index, userDataClassOld) in zip(self.userArray.indices, self.userArray) { // enumerated()はやめた // 参考：https://qiita.com/a-beco/items/0fcfa69cca20a0ba601c
//
//                                    // 差し替えるため一度削除する
//                                    self.userArray.remove(at: index)
//
//                                    let userDataClassNew = UserData(nickname: userDataClassOld.nickname!,
//                                                                    idForSearch: userDataClassOld.idForSearch!,
//                                                                    selfIntroduction: userDataClassOld.selfIntroduction!,
//                                                                    userId: userDataClassOld.userId!,
//                                                                    iconImageString: userDataClassOld.iconImageString!,
//                                                                    followingsList: followings_list)
//
//                                    // 削除したところに更新済みのデータを追加する
//                                    self.userArray.insert(userDataClassNew, at: index)
//                                }
//
//                                // TableViewを再表示する
//                                self.tableView.reloadData()
//                            } else {
                            self.userArray.removeAll()
                            self.isAllUsersDataSet = false
                            
                            Database.database().reference().child("users").observeSingleEvent(of: .value, with: { (snapshot) in
                                let users_all = snapshot.value as! [String:[String: Any]] // ここは必ず存在
                                
                                for user_id in users_all.keys {
                                    let user_each = users_all[user_id]

                                    let idForSearch = user_each!["id_for_search"] as! String
                                    
                                    if idForSearch == searchText {
                                        let iconImageString = user_each!["icon_image"] as! String
                                        let nickname = user_each!["nickname"] as! String
                                        let selfIntroduction = user_each!["self_introduction"] as! String
                                        
                                        let userDataClass = UserData(nickname: nickname,
                                                                     idForSearch: idForSearch,
                                                                     selfIntroduction: selfIntroduction,
                                                                     userId: user_id,
                                                                     iconImageString: iconImageString,
                                                                     followingsList: followings_list,
                                                                     myId: user.uid)
                                        
                                        self.userArray.append(userDataClass)
                                    }
                                }
                                self.userArray.sort(by: {$0.idForSearch! > $1.idForSearch!})
                                
                                // TableViewを再表示する
                                self.tableView.reloadData()
                                
//                                    self.isSearchedUsersDataSet = true
                                self.isAllUsersDataSet = false
                            })
//                            }
                        })
                        
                        // DatabaseのobserveEventが上記コードにより登録されたため
                        // trueとする
                        self.searchedUserRefObserving = true
                    }
                }
            }
            self.previousSearchText = searchText
        } else {
            self.deleteAllUsersWithRemovingObservers()
            self.deleteSearchedUsersWithRemovingObservers()
            self.showAllUsers()
            SVProgressHUD.showError(withStatus: "入力して下さい")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
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
        
//        // currentUserがnilならログインしていない
//        if Auth.auth().currentUser == nil {
//            // ログインしていないときの処理
//            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "Login")
//            self.present(loginViewController!, animated: true, completion: nil)
//        }
        
        let user = Auth.auth().currentUser
        if let user = user {
            self.currentUserUid = user.uid
            
            self.showAllUsers()
        } else {
            // ログアウトを検出したら、一旦テーブルをクリアしてオブザーバーを削除する。
            self.deleteAllUsersWithRemovingObservers()
            self.deleteSearchedUsersWithRemovingObservers()
            
            // ログインしていないときの処理
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "Login")
            self.present(loginViewController!, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // ログアウトを検出したら、一旦テーブルをクリアしてオブザーバーを削除する。
        self.deleteAllUsersWithRemovingObservers()
        self.deleteSearchedUsersWithRemovingObservers()
        
        super.viewWillDisappear(animated)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得してデータを設定する
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        cell.setUserData(self.userArray[indexPath.row])
        
        // セル内のボタンのアクションをソースコードで設定する
        cell.followButton.addTarget(self, action:#selector(handleFollowButton(_:forEvent:)), for: .touchUpInside)
        
        return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.allUserRefObserving = false
        let userDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: "UserDetail") as! UserDetailViewController
        userDetailViewController.userData = self.userArray[indexPath.row]
        self.present(userDetailViewController, animated: true, completion: nil)
    }
    
    // セル内のボタンがタップされた時に呼ばれるメソッド
    @objc func handleFollowButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: FollowButtonがタップされました。")
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        // 配列からタップされたインデックスのデータを取り出す
        let userDataClass = self.userArray[indexPath!.row]
        
        let user = Auth.auth().currentUser
        if let user = user {
            Database.database().reference().child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                let userDataInSnapshot = snapshot.value as! [String: Any] // userDataは必ず存在
                var existingFollowingsList = (userDataInSnapshot["followings_list"] as? [String]) ?? [String]()
                
                if userDataClass.isFollowed { // 含まれていれば削除
                    let index = existingFollowingsList.firstIndex(of: userDataClass.userId!)!
                    existingFollowingsList.remove(at: index)
                    Database.database().reference().child("users").child(user.uid).child("followings_list").setValue(existingFollowingsList)
                    
                    Database.database().reference().child("users").child(userDataClass.userId!).observeSingleEvent(of: .value, with: { (snapshotInside) in
                        let userDataInSnapshotInside = snapshotInside.value as! [String: Any]
                        var existingFollowersList = (userDataInSnapshotInside["followers_list"] as? [String]) ?? [String]()
                        let indexInside = existingFollowersList.firstIndex(of: user.uid)!
                        existingFollowersList.remove(at: indexInside)
                        Database.database().reference().child("users").child(userDataClass.userId!).child("followers_list").setValue(existingFollowersList)
                    })
                } else { // 含まれなければ追加
                    existingFollowingsList.append(userDataClass.userId!)
                    Database.database().reference().child("users").child(user.uid).child("followings_list").setValue(existingFollowingsList)
                    
                    Database.database().reference().child("users").child(userDataClass.userId!).observeSingleEvent(of: .value, with: { (snapshotInside) in
                        let userDataInSnapshotInside = snapshotInside.value as! [String: Any]
                        var existingFollowersList = (userDataInSnapshotInside["followers_list"] as? [String]) ?? [String]()
                        existingFollowersList.append(user.uid)
                        Database.database().reference().child("users").child(userDataClass.userId!).child("followers_list").setValue(existingFollowersList)
                    })
                }
            })
        }
    }
    
    private func showAllUsers() {
        let user = Auth.auth().currentUser
        if let user = user {
            self.currentUserUid = user.uid
            
            if self.allUserRefObserving == false {
                Database.database().reference().child("users").child(user.uid).child("followings_list").observe(.value, with: { (snapshot) in
                    let followings_list = (snapshot.value as? [String]) ?? [String]()
                    
                    if self.isAllUsersDataSet {
                        for (index, userDataClassOld) in zip(self.userArray.indices, self.userArray) { // enumerated()はやめた // 参考：https://qiita.com/a-beco/items/0fcfa69cca20a0ba601c
                            
                            // 差し替えるため一度削除する
                            self.userArray.remove(at: index)
                            
                            var userDataClassNew = UserData(nickname: userDataClassOld.nickname!,
                                                            idForSearch: userDataClassOld.idForSearch!,
                                                            selfIntroduction: userDataClassOld.selfIntroduction!,
                                                            userId: userDataClassOld.userId!,
                                                            iconImageString: userDataClassOld.iconImageString!,
                                                            followingsList: followings_list,
                                                            myId: user.uid)
                            
                            // 削除したところに更新済みのデータを追加する
                            self.userArray.insert(userDataClassNew, at: index)
                        }
                        
                        // TableViewを再表示する
                        self.tableView.reloadData()
                    } else {
                        self.userArray.removeAll()
                        self.isAllUsersDataSet = false
                        
                        Database.database().reference().child("users").observeSingleEvent(of: .value, with: { (snapshot) in
                            let users_all = snapshot.value as! [String:[String: Any]] // ここは必ず存在
                            
                            for user_id in users_all.keys {
                                let user_each = users_all[user_id]
                                
                                let iconImageString = user_each!["icon_image"] as! String
                                let nickname = user_each!["nickname"] as! String
                                let idForSearch = user_each!["id_for_search"] as! String
                                let selfIntroduction = user_each!["self_introduction"] as! String
                                
                                let userDataClass = UserData(nickname: nickname,
                                                             idForSearch: idForSearch,
                                                             selfIntroduction: selfIntroduction,
                                                             userId: user_id,
                                                             iconImageString: iconImageString,
                                                             followingsList: followings_list,
                                                             myId: user.uid)
                                
                                self.userArray.append(userDataClass)
                            }
                            self.userArray.sort(by: {$0.idForSearch! > $1.idForSearch!})
                            
                            // TableViewを再表示する
                            self.tableView.reloadData()
                            
                            self.isAllUsersDataSet = true
//                            self.isSearchedUsersDataSet = false
                        })
                    }
                })
                
                // DatabaseのobserveEventが上記コードにより登録されたため
                // trueとする
                self.allUserRefObserving = true
            }
        }
    }
    
    private func deleteAllUsersWithRemovingObservers() {
        // テーブルをクリアする
        self.userArray.removeAll()
        self.isAllUsersDataSet = false
        self.tableView.reloadData()
        
        // オブザーバーを削除する
        if self.allUserRefObserving == true {
            Database.database().reference().child("users").child(self.currentUserUid).child("followings_list").removeAllObservers()
            
            // DatabaseのobserveEventが上記コードにより解除されたため
            // falseとする
            self.allUserRefObserving = false
        }
    }
    
    private func deleteSearchedUsersWithRemovingObservers() {
        // テーブルをクリアする
        self.userArray.removeAll()
        self.isAllUsersDataSet = false
        self.tableView.reloadData()
        
        // オブザーバーを削除する
        if self.searchedUserRefObserving == true {
            Database.database().reference().child("users").child(self.currentUserUid).child("followings_list").removeAllObservers()
            
            // DatabaseのobserveEventが上記コードにより解除されたため
            // falseとする
            self.searchedUserRefObserving = false
        }
    }
}
