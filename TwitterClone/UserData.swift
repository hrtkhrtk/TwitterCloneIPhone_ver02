//
//  UserData.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/10.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit

class UserData: NSObject {
    var nickname: String?
    var idForSearch: String?
    var selfIntroduction: String?
    var userId: String?
    var iconImageString: String?
    var iconImage: UIImage?
    
    init(nickname: String, idForSearch: String, selfIntroduction: String, userId: String, iconImageString: String) {
        self.nickname = nickname
        self.idForSearch = idForSearch
        self.selfIntroduction = selfIntroduction
        self.userId = userId
        self.iconImageString = iconImageString
        self.iconImage = UIImage(data: Data(base64Encoded: self.iconImageString!, options: .ignoreUnknownCharacters)!)
    }
}
