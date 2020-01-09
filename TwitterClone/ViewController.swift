//
//  ViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    @IBAction func handleSettingButton(_ sender: Any) {
        let popupViewController = storyboard?.instantiateViewController(withIdentifier: "Popup")
        popupViewController!.modalPresentationStyle = .overFullScreen
        //popupViewController!.modalPresentationStyle = .overCurrentContext
        popupViewController!.modalTransitionStyle = .crossDissolve
        self.present(popupViewController!, animated: false, completion: nil)
    }
    
    //let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "Main")
    //let contentViewController = UINavigationController(rootViewController: UIViewController())
    let sidemenuViewController = SidemenuViewController()
    private var isShownSidemenu: Bool {
        return sidemenuViewController.parent == self
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //menuButton.addTarget(self, action:#selector(sidemenuBarButtonTapped(sender:)), for: .touchUpInside)
        menuButton.target = self // 参考：https://stackoverflow.com/questions/2333638/how-to-set-target-and-action-for-uibarbuttonitem-at-runtime 「Just set the UIBarButtonItem's target and action properties directly.」
        menuButton.action = #selector(sidemenuBarButtonTapped(sender:))
        
        let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "Main")
        //addChildViewController(mainViewController!)
        addChild(mainViewController!)
        view.addSubview(mainViewController!.view)
        //mainViewController!.didMove(toParentViewController: self)
        mainViewController!.didMove(toParent: self)
    }
    
    @objc private func sidemenuBarButtonTapped(sender: Any) {
        showSidemenu(animated: true)
    }

    private func showSidemenu(contentAvailability: Bool = true, animated: Bool) {
        if isShownSidemenu { return }
        
        let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "Main")
        
        //addChildViewController(sidemenuViewController)
        addChild(sidemenuViewController)
        sidemenuViewController.view.autoresizingMask = .flexibleHeight
        //sidemenuViewController.view.frame = contentViewController.view.bounds
        sidemenuViewController.view.frame = mainViewController!.view.bounds
        //view.insertSubview(sidemenuViewController.view, aboveSubview: contentViewController.view)
        view.insertSubview(sidemenuViewController.view, aboveSubview: mainViewController!.view)
        //sidemenuViewController.didMove(toParentViewController: self)
        sidemenuViewController.didMove(toParent: self)
        if contentAvailability {
            sidemenuViewController.showContentView(animated: animated)
        }
    }

    private func hideSidemenu(animated: Bool) {
        if !isShownSidemenu { return }
        
        sidemenuViewController.hideContentView(animated: animated, completion: { (_) in
            //self.sidemenuViewController.willMove(toParentViewController: nil)
            self.sidemenuViewController.willMove(toParent: nil)
            //self.sidemenuViewController.removeFromParentViewController()
            self.sidemenuViewController.removeFromParent()
            self.sidemenuViewController.view.removeFromSuperview()
        })
    }
}

//extension MainViewController: SidemenuViewControllerDelegate {
extension ViewController: SidemenuViewControllerDelegate {
    func parentViewControllerForSidemenuViewController(_ sidemenuViewController: SidemenuViewController) -> UIViewController {
        return self
    }
    
    func shouldPresentForSidemenuViewController(_ sidemenuViewController: SidemenuViewController) -> Bool {
        /* You can specify sidemenu availability */
        return true
    }
    
    func sidemenuViewControllerDidRequestShowing(_ sidemenuViewController: SidemenuViewController, contentAvailability: Bool, animated: Bool) {
        //showSidemenu(contentAvailability: contentAvailability, animated: animated)
        showSidemenu(contentAvailability: contentAvailability, animated: animated)
    }
    
    func sidemenuViewControllerDidRequestHiding(_ sidemenuViewController: SidemenuViewController, animated: Bool) {
        hideSidemenu(animated: animated)
    }
    
    func sidemenuViewController(_ sidemenuViewController: SidemenuViewController, didSelectItemAt indexPath: IndexPath) {
        hideSidemenu(animated: true)
    }
}
