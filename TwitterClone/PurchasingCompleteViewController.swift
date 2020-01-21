//
//  PurchasingCompleteViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase

class PurchasingCompleteViewController: UIViewController {
    
    var price:Int!
    var purchaseTo:Int64!
    
    @IBOutlet weak var purchaseToTextLabel: UILabel!
    @IBOutlet weak var priceTextLabel: UILabel!
    
    @IBAction func handleToMainButton(_ sender: Any) {
        let navigation = self.storyboard?.instantiateInitialViewController() as! UINavigationController
        self.present(navigation, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.purchaseToTextLabel.text = Const.getDateTime(time:self.purchaseTo, format:"yyyy/MM/dd HH:mm:ss")
        self.priceTextLabel.text = String(self.price)
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
