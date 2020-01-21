//
//  PurchasingViewController.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import Alamofire
import SwiftyJSON
import PAYJP

class PurchasingViewController: UIViewController {
    
    var availableTo:Int64!
    
    @IBOutlet weak var availableToTextLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var priceTextLabel: UILabel!
    @IBOutlet weak var fieldCardNumber: UITextField!
    @IBOutlet weak var fieldCardCvc: UITextField!
    @IBOutlet weak var fieldCardYear: UITextField!
    @IBOutlet weak var fieldCardMonth: UITextField!
    @IBOutlet weak var fieldCardName: UITextField!
    
    private let payjpClient: PAYJP.APIClient = PAYJP.APIClient.shared
    
    @IBAction func handleBackButton(_ sender: Any) {
        // 全てのモーダルを閉じる
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handlePurchaseButton(_ sender: Any) {
        print("DEBUG_PRINT: PurchaseButtonがタップされました。")
        
        // キーボードを閉じる
        self.view.endEditing(true)
        
        if let number = fieldCardNumber.text,
            let cvc = fieldCardCvc.text,
            let year = fieldCardYear.text,
            let month = fieldCardMonth.text,
            let name = fieldCardName.text {
            
            if number.isEmpty || cvc.isEmpty || year.isEmpty || month.isEmpty || name.isEmpty {
                SVProgressHUD.showError(withStatus: "必要項目を入力して下さい")
                return
            }
            
            let user = Auth.auth().currentUser
            if let user = user {
                let input_time:Int64 = Int64(self.datePicker.date.timeIntervalSince1970*1000)
                
                let price:Int!
                if input_time >= self.availableTo {
                    let interval_Int64 = input_time - self.availableTo!
                    let interval_Double = Double(interval_Int64) // iPhoneのほとんどは（既に）64bit
                    let price_double = interval_Double / (24*60*60*1000) * 10
                    //let price:Int = Int(ceil(price_double)) // 1日10円（24時間10円）
                    price = Int(ceil(price_double)) // 1日10円（24時間10円）
                    //self.priceTextLabel.text = String(price)
                } else {
                    self.priceTextLabel.text = String(0)
                    SVProgressHUD.showError(withStatus: "available_toより先の日付を入力してください")
                    return
                }
                
                if let price = price {
                    print("createToken")
                    payjpClient.createToken(
                        with: number,
                        cvc: cvc,
                        expirationMonth: month,
                        expirationYear: year,
                        name: name) { [weak self] result in
                            switch result {
                            case .success(let token):
                                DispatchQueue.main.async {
                                    //self?.labelTokenId.text = token.identifer
                                    //                        self?.tableView.reloadData()
                                    //                        self?.showToken(token: token)
                                    
                                    //print(token.identifer) // test
                                    let dataToSend_Map = ["payjp-token": token.identifer,
                                                          "price": String(price),
                                                          "purchaseTo": String(input_time),
                                                          "currentUID": user.uid]
                                    Alamofire.request("https://twittercloneiphone-api-ver02.herokuapp.com/payment",
                                                      method: .post,
                                                      parameters: dataToSend_Map,
                                                      encoding: JSONEncoding.default,
                                                      headers: nil).responseJSON { response in
                                                        if response.result.isSuccess {
                                                            if let returnValue = response.result.value {
                                                                print(JSON(returnValue))
                                                                
                                                                let result_Map = JSON(returnValue)
                                                                
                                                                if result_Map["status"] == "success" {
                                                                    let purchasingCompleteViewController = self?.storyboard?.instantiateViewController(withIdentifier: "PurchasingComplete") as! PurchasingCompleteViewController
                                                                    purchasingCompleteViewController.price = Int(result_Map["price"].string!)
//                                                                    print("test result_Map[price]") // test
//                                                                    print(result_Map["price"]) // test // 60
//                                                                    print(result_Map["price"].string) // test // Optional("60")
//                                                                    print("test result_Map[purchaseTo]") // test
//                                                                    print(result_Map["purchaseTo"]) // test // 1581386399000
//                                                                    print(type(of: result_Map["purchaseTo"])) // test // JSON
//                                                                    print(result_Map["purchaseTo"].string) // test // nil
//                                                                    print(result_Map["purchaseTo"].int) // test // Optional(1582340399000)
//                                                                    print(result_Map["purchaseTo"].int64) // test // Optional(1582775999000)
//                                                                    //print(result_Map["purchaseTo"].string!) // test // error
//                                                                    //print(Int(result_Map["purchaseTo"].string!)) // test // error
//                                                                    //print(Int64(result_Map["purchaseTo"].string!)) // test // error
                                                                    //purchasingCompleteViewController.purchaseTo = Int64(result_Map["purchaseTo"].string!)
                                                                    //purchasingCompleteViewController.purchaseTo = Int64(Int(result_Map["purchaseTo"].string!)) // iPhoneのほとんどは（既に）64bit
                                                                    purchasingCompleteViewController.purchaseTo = result_Map["purchaseTo"].int64
                                                                    self!.present(purchasingCompleteViewController, animated: true, completion: nil)
                                                                } else {
                                                                    SVProgressHUD.showError(withStatus: result_Map["status"].string)
                                                                }
                                                            }
                                                        } else {
                                                            SVProgressHUD.showError(withStatus: "Error")
                                                            print("Error!")
                                                        }
                                    }
                                }
                            case .failure(let error):
                                if let payError = error.payError {
                                    print("[errorResponse] \(payError.description)")
                                    SVProgressHUD.showError(withStatus: "payError")
                                }
                                
//                                DispatchQueue.main.async {
//                                    //self?.labelTokenId.text = ""
//                                    //                        self?.showError(error: error)
//                                }
                            }
                    }
                }
            }
        } else {
            SVProgressHUD.showError(withStatus: "必要項目を入力して下さい")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // ここはviewDidAppearに書いてもいいかも（たぶんどっちでもいい）
        let user = Auth.auth().currentUser
        if let user = user {
            Database.database().reference().child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                let data = snapshot.value as! [String: Any]
                
                let available_to = data["available_to"]! as! Int64
                self.availableTo = available_to
                self.availableToTextLabel.text = Const.getDateTime(time:available_to, format:"yyyy/MM/dd HH:mm:ss")
                
                let dateUnix:TimeInterval = TimeInterval(Int64(available_to / 1000)) // Int()は小数点以下切り捨てでfloorと同じ。
                let date = Date(timeIntervalSince1970: dateUnix)
                self.datePicker.date = date
            }) { (error) in
                SVProgressHUD.showError(withStatus: "Firebaseのエラー")
                print("DEBUG_PRINT: " + error.localizedDescription)
            }
        }
        
        self.datePicker.addTarget(self, action:#selector(dateChange), for: .valueChanged)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    @objc func dateChange() {
        print("DEBUG_PRINT: dateChange")
        
        let input_time:Int64 = Int64(self.datePicker.date.timeIntervalSince1970*1000)
        
        if input_time >= self.availableTo {
//            //print(input_time) // test
//            //print(self.availableTo) // test
//            //print(input_time - self.availableTo) // test
//            print(input_time - self.availableTo!) // test
//            let interval_Int64 = input_time - self.availableTo! // test
//            //print(interval / (24*60*60*1000)) // test
//            //print(interval / (24*60*60*1000) * 10) // test
//            print(type(of: interval_Int64)) // test // Int64
//            //let price_double = interval_Int64 / (24*60*60*1000) * 10 // test
//            //print(price_double) // test // 0
//            //print(type(of: price_double)) // test // Int64
//            //let interval_Int = Int(interval_Int64) // test
//            //print(interval_Int) // test
//            //print(type(of: interval_Int)) // test // Int
//            //let price_double = interval_Int / (24*60*60*1000) * 10 // test
//            //print(price_double) // test // 0
//            //print(type(of: price_double)) // test // Int
//            let interval_Double = Double(interval_Int64) // test
//            //print(interval_Double) // test
//            //print(type(of: interval_Double)) // test // Double
//            let price_double = interval_Double / (24*60*60*1000) * 10 // test
//            print(price_double) // test
//            //print(type(of: price_double)) // test // Double
//            let price_double_ceiled = ceil(price_double) // test
//            print(price_double_ceiled) // test
//            print(type(of: price_double_ceiled)) // test // Double
//            let price:Int = Int(price_double_ceiled) // test
//            print(price) // test
//            print(type(of: price)) // test // Int
            
            
            let interval_Int64 = input_time - self.availableTo!
            let interval_Double = Double(interval_Int64) // iPhoneのほとんどは（既に）64bit
            let price_double = interval_Double / (24*60*60*1000) * 10
            let price:Int = Int(ceil(price_double)) // 1日10円（24時間10円）
            self.priceTextLabel.text = String(price)
        } else {
            self.priceTextLabel.text = String(0)
            SVProgressHUD.showError(withStatus: "available_toより先の日付を入力してください")
        }
    }
}
