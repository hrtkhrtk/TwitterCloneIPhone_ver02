//
//  FollowingsListViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/16.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class FollowingsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var userArray: [UserData] = []
    
    // DatabaseのobserveEventの登録状態を表す
    var userRefObserving = false
    
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
        
        let user = Auth.auth().currentUser
        if let user = user {
            self.currentUserUid = user.uid
            
            self.userArray.removeAll()
            // TableViewを再表示する
            self.tableView.reloadData()
            
            if self.userRefObserving == false {
                Database.database().reference().child("users").child(user.uid).child("followings_list").observe(.value, with: { snapshot in
                    self.userArray.removeAll()
                    
                    let followings_list = (snapshot.value as? [String]) ?? [String]()
                    
                    if followings_list.isEmpty {
                        // TableViewを再表示する
                        self.tableView.reloadData()
                    }
                    
                    for user_id in followings_list {
                        Database.database().reference().child("users").child(user_id).observeSingleEvent(of: .value, with: { snapshotInside in
                            let user_each = snapshotInside.value as! [String: Any] // ここは必ず存在
                            
                            let iconImageString = user_each["icon_image"] as! String
                            let nickname = user_each["nickname"] as! String
                            let idForSearch = user_each["id_for_search"] as! String
                            let selfIntroduction = user_each["self_introduction"] as! String
                            
                            let userDataClass = UserData(nickname: nickname,
                                                         idForSearch: idForSearch,
                                                         selfIntroduction: selfIntroduction,
                                                         userId: user_id,
                                                         iconImageString: iconImageString,
                                                         followingsList: followings_list,
                                                         myId: user.uid)
                            
                            self.userArray.append(userDataClass)
                            
                            self.userArray.sort(by: {$0.idForSearch! > $1.idForSearch!})
                            
                            // TableViewを再表示する
                            self.tableView.reloadData()
                        })
                    }
                    //self.userArray.sort(by: {$0.idForSearch! > $1.idForSearch!}) // データ取得が間に合ってないっぽい
                    
                    // TableViewを再表示する
                    //self.tableView.reloadData() // データ取得が間に合ってないっぽい
                })
                
                // DatabaseのobserveEventが上記コードにより登録されたため
                // trueとする
                self.userRefObserving = true
            }
        } else {
            if self.userRefObserving == true {
                // ログアウトを検出したら、一旦テーブルをクリアしてオブザーバーを削除する。
                // テーブルをクリアする
                self.userArray.removeAll()
                self.tableView.reloadData()
                
                // オブザーバーを削除する // これが必要なのか不明
                Database.database().reference().child("users").child(self.currentUserUid).child("followings_list").removeAllObservers()
                
                self.currentUserUid = ""
                
                // DatabaseのobserveEventが上記コードにより解除されたため
                // falseとする
                self.userRefObserving = false
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.userRefObserving == true {
            // ログアウトを検出したら、一旦テーブルをクリアしてオブザーバーを削除する。
            // テーブルをクリアする
            self.userArray.removeAll()
            self.tableView.reloadData()
            
            // オブザーバーを削除する // これが必要なのか不明
            Database.database().reference().child("users").child(self.currentUserUid).child("followings_list").removeAllObservers()
            
            self.currentUserUid = ""
            
            // DatabaseのobserveEventが上記コードにより解除されたため
            // falseとする
            self.userRefObserving = false
        }
        
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
}
