//
//  UserTableViewCell.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nicknameTextLabel: UILabel!
    @IBOutlet weak var idForSearchTextLabel: UILabel!
    @IBOutlet weak var selfIntroductionTextLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setUserData(_ userData: UserData) {
        self.iconImageView.image = userData.iconImage
        self.nicknameTextLabel.text = userData.nickname
        self.idForSearchTextLabel.text = userData.idForSearch
        self.selfIntroductionTextLabel.text = userData.selfIntroduction
        
        if userData.isFollowed {
            self.followButton.setTitle("unfollow", for: .normal)
        } else {
            self.followButton.setTitle("follow", for: .normal)
        }
        
        //print(userData.idForSearch) // test
        //print("test21")
        if userData.isMe {
            self.followButton.isHidden = true
            //print("test22")
        } else {
            self.followButton.isHidden = false
        }
        //print("test23")
    }
}
