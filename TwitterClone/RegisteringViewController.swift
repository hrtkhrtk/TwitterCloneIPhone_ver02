//
//  RegisteringViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit

class RegisteringViewController: UIViewController {
    
    @IBOutlet weak var selfIntroductionTextField: UITextField!
    @IBOutlet weak var iconImageAsButton: UIButton!
    @IBOutlet weak var backgroundImageAsButton: UIButton!
    
    @IBAction func handleRegisterButton(_ sender: Any) {
    }
    
    @IBAction func handleSkipButton(_ sender: Any) {
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
