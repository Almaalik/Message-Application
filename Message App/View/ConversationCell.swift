//
//  ConversationCell.swift
//  Message App
//
//  Created by macbook  on 24/02/21.
//  Copyright © 2021 Almaalik. All rights reserved.
//

import UIKit
import SDWebImage

class ConversationCell: UITableViewCell {
    @IBOutlet weak var otherUserPic: UIImageView?
    @IBOutlet var otherUserName: UILabel!
    @IBOutlet var latestMessage: UILabel!
    
    override func awakeFromNib() {
              super.awakeFromNib()

          }
       override func setSelected(_ selected: Bool, animated: Bool) {
                 super.setSelected(selected, animated: animated)
             }
  
}

