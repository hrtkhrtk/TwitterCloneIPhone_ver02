//
//  PostData.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/10.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit

class PostData: NSObject {
    var nickname: String?
    var text: String?
    var createdAt: Int64?
    //var favoritersList: [String] = []
    var favoritersList: [String]?
    var userId: String?
    var postId: String?
    var iconImageString: String?
    var iconImage: UIImage?
    
    init(nickname: String, text: String, createdAt: Int64, favoritersList: [String], userId: String, postId: String, iconImageString: String) {
        self.nickname = nickname
        self.text = text
        self.createdAt = createdAt
        self.favoritersList = favoritersList
        self.userId = userId
        self.postId = postId
        self.iconImageString = iconImageString
        self.iconImage = UIImage(data: Data(base64Encoded: self.iconImageString!, options: .ignoreUnknownCharacters)!)
    }
}
