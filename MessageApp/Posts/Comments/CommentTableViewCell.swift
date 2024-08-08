//
//  CommentTableViewCell.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/14/24.
//

import UIKit

class CommentTableViewCell: UITableViewCell {

    @IBOutlet weak var authorImg: UIImageView!
    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        authorImg.layer.cornerRadius = authorImg.frame.size.width / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
