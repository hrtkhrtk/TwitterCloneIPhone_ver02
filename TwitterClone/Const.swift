//
//  Const.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/11.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import Foundation

struct Const {
    static let id__iconImage_from_RegisteringView = 1
    static let id__backgroundImage_from_RegisteringView = 2
    static let id__iconImage_from_SettingView = 3
    static let id__backgroundImage_from_SettingView = 4
    
    static func getDateTime(time:Int64, format:String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        let dateUnix:TimeInterval = TimeInterval(Int64(time / 1000)) // Int()は小数点以下切り捨てでfloorと同じ。
        let date = Date(timeIntervalSince1970: dateUnix)
        let dateString = formatter.string(from: date)
        
        return dateString
    }
}
