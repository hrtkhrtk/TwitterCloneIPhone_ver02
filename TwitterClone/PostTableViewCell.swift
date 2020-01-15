//
//  PostTableViewCell.swift
//  TwitterClone
//
//  Created by hirotaka.iwasaki on 2020/01/09.
//  Copyright © 2020 hrtkhrtk. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nicknameTextLabel: UILabel!
    @IBOutlet weak var createdAtTextLabel: UILabel!
    @IBOutlet weak var postTextLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var favoritesNumTextLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setPostData(_ postData: PostData) {
        self.iconImageView.image = postData.iconImage
        self.nicknameTextLabel.text = postData.nickname
        self.createdAtTextLabel.text = Const.getDateTime(time:postData.createdAt!, format:"yyyy/MM/dd HH:mm:ss")
        self.postTextLabel.text = postData.text
        let favoritesNum = postData.favoritersList!.count
        self.favoritesNumTextLabel.text = String(favoritesNum)
        
        if postData.isFaved {
            let buttonImage = UIImage(named: "like_exist")
            self.favoriteButton.setImage(buttonImage, for: .normal)
        } else {
            let buttonImage = UIImage(named: "like_none")
            self.favoriteButton.setImage(buttonImage, for: .normal)
        }
    }
}
