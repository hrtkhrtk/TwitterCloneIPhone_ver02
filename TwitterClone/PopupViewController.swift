//
//  PopupViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit

class PopupViewController: UIViewController {
    
    @IBAction func handleToSettingButton(_ sender: Any) {
        // 画面を表示する
        let settingViewController = self.storyboard?.instantiateViewController(withIdentifier: "Setting")
        self.present(settingViewController!, animated: true, completion: nil)
    }
    
    @IBAction func handleToPurchasingButton(_ sender: Any) {
        // 画面を表示する
        let purchasingViewController = self.storyboard?.instantiateViewController(withIdentifier: "Purchasing")
        self.present(purchasingViewController!, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // ポップアップの外側をタップした時にポップアップを閉じる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        var tapLocation: CGPoint = CGPoint()
        // タッチイベントを取得する
        let touch = touches.first
        // タップした座標を取得する
        tapLocation = touch!.location(in: self.view)
        
        let popUpView: UIView = self.view.viewWithTag(100)! as UIView

        if !popUpView.frame.contains(tapLocation) {
            self.dismiss(animated: false, completion: nil)
        }
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
