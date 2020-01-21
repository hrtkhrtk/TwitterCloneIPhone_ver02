//
//  SidemenuViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase

protocol SidemenuViewControllerDelegate: class {
    func sidemenuViewControllerDidRequestShowing(_ sidemenuViewController: SidemenuViewController, contentAvailability: Bool, animated: Bool)
    func sidemenuViewControllerDidRequestHiding(_ sidemenuViewController: SidemenuViewController, animated: Bool)
    func sidemenuViewController(_ sidemenuViewController: SidemenuViewController, didSelectItemAt indexPath: IndexPath)
}

class SidemenuViewController: UIViewController {
    private let contentView = UIView(frame: .zero)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    weak var delegate: SidemenuViewControllerDelegate?
    private var beganLocation: CGPoint = .zero
    private var beganState: Bool = false
    var isShown: Bool {
        return self.parent != nil
    }
    private var contentMaxWidth: CGFloat {
        return view.bounds.width * 0.8
    }
    private var contentRatio: CGFloat {
        get {
            return contentView.frame.maxX / contentMaxWidth
        }
        set {
            let ratio = min(max(newValue, 0), 1)
            contentView.frame.origin.x = contentMaxWidth * ratio - contentView.frame.width
            contentView.layer.shadowColor = UIColor.black.cgColor
            contentView.layer.shadowRadius = 3.0
            contentView.layer.shadowOpacity = 0.8
            
            view.backgroundColor = UIColor(white: 0, alpha: 0.3 * ratio)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var contentRect = view.bounds
        contentRect.size.width = contentMaxWidth
        contentRect.origin.x = -contentRect.width
        contentView.frame = contentRect
        contentView.backgroundColor = .white
        contentView.autoresizingMask = .flexibleHeight
        view.addSubview(contentView)
        
        tableView.frame = contentView.bounds
        tableView.separatorInset = .zero
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Default")
        contentView.addSubview(tableView)
        tableView.reloadData()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(sender:)))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
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
    
    @objc private func backgroundTapped(sender: UITapGestureRecognizer) {
        hideContentView(animated: true) { (_) in
            self.willMove(toParent: nil)
            self.removeFromParent()
            self.view.removeFromSuperview()
        }
    }

    func showContentView(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.contentRatio = 1.0
            }
        } else {
            contentRatio = 1.0
        }
    }
    
    func hideContentView(animated: Bool, completion: ((Bool) -> Swift.Void)?) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.contentRatio = 0
            }, completion: { (finished) in
                completion?(finished)
            })
        } else {
            contentRatio = 0
            completion?(true)
        }
    }
}

extension SidemenuViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath)
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "posts"
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "search_posts"
        } else if indexPath.row == 2 {
            cell.textLabel?.text = "search_users"
        } else if indexPath.row == 3 {
            cell.textLabel?.text = "followings_list"
        } else if indexPath.row == 4 {
            cell.textLabel?.text = "followers_list"
        } else if indexPath.row == 5 {
            cell.textLabel?.text = "favorites_list"
        } else if indexPath.row == 6 {
            cell.textLabel?.text = "my_posts"
        } else if indexPath.row == 7 {
            cell.textLabel?.text = "policy"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.sidemenuViewController(self, didSelectItemAt: indexPath)
        
        if indexPath.row == 0 { // "posts"
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // 参考：http://crossbridge-lab.hatenablog.com/entry/2015/12/14/073000
            let navigation = storyboard.instantiateInitialViewController() as! UINavigationController
            self.present(navigation, animated: true, completion: nil)
        } else if indexPath.row == 1 { // "search_posts"
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // 参考：http://crossbridge-lab.hatenablog.com/entry/2015/12/14/073000
            let searchPostsViewController = storyboard.instantiateViewController(withIdentifier: "SearchPosts")
            self.present(searchPostsViewController, animated: true, completion: nil)
        } else if indexPath.row == 2 { // "search_users"
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // 参考：http://crossbridge-lab.hatenablog.com/entry/2015/12/14/073000
            let usersListViewController = storyboard.instantiateViewController(withIdentifier: "UsersList")
            self.present(usersListViewController, animated: true, completion: nil)
        } else if indexPath.row == 3 { // "followings_list"
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // 参考：http://crossbridge-lab.hatenablog.com/entry/2015/12/14/073000
            let followingsListViewController = storyboard.instantiateViewController(withIdentifier: "FollowingsList")
            self.present(followingsListViewController, animated: true, completion: nil)
        } else if indexPath.row == 4 { // "followers_list"
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // 参考：http://crossbridge-lab.hatenablog.com/entry/2015/12/14/073000
            let followersListViewController = storyboard.instantiateViewController(withIdentifier: "FollowersList")
            self.present(followersListViewController, animated: true, completion: nil)
        } else if indexPath.row == 5 { // "favorites_list"
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // 参考：http://crossbridge-lab.hatenablog.com/entry/2015/12/14/073000
            let favoritesListViewController = storyboard.instantiateViewController(withIdentifier: "FavoritesList")
            self.present(favoritesListViewController, animated: true, completion: nil)
        } else if indexPath.row == 6 { // "my_posts"
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // 参考：http://crossbridge-lab.hatenablog.com/entry/2015/12/14/073000
            let myPostsViewController = storyboard.instantiateViewController(withIdentifier: "MyPosts")
            self.present(myPostsViewController, animated: true, completion: nil)
        } else if indexPath.row == 7 { // "policy"
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // 参考：http://crossbridge-lab.hatenablog.com/entry/2015/12/14/073000
            let policyViewController = storyboard.instantiateViewController(withIdentifier: "Policy")
            self.present(policyViewController, animated: true, completion: nil)
        }
    }
}

extension SidemenuViewController: UIGestureRecognizerDelegate {
    internal func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: tableView)
        if tableView.indexPathForRow(at: location) != nil {
            return false
        }
        return true
    }
}
