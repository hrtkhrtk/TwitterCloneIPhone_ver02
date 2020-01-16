//
//  MyPostsViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/16.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit

class MyPostsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func handleBackButton(_ sender: Any) {
        let navigation = self.storyboard?.instantiateInitialViewController() as! UINavigationController
        self.present(navigation, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
