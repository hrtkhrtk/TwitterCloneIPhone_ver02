//
//  SettingViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase

class SettingViewController: UIViewController {
    
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var selfIntroductionTextField: UITextField!
    @IBOutlet weak var iconImageAsButton: UIButton!
    @IBOutlet weak var backgroundImageAsButton: UIButton!
    @IBOutlet weak var emailTextLabel: UILabel!
    @IBOutlet weak var idForSearchTextLabel: UILabel!
    @IBOutlet weak var createdAtTextLabel: UILabel!
    @IBOutlet weak var statusTextLabel: UILabel!
    @IBOutlet weak var availableToTextLabel: UILabel!
    
    @IBAction func handleChangeButton(_ sender: Any) {
    }
    
    @IBAction func handleToPurchasingButton(_ sender: Any) {
    }
    
    @IBAction func handleLogoutButton(_ sender: Any) {
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
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
