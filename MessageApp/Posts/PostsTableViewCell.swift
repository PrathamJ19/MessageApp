//
//  PostsTableViewCell.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/11/24.
//

import UIKit

class PostsTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var authorTEXT: UILabel!
    @IBOutlet weak var postIMG: UIImageView!
    @IBOutlet weak var captionTEXT: UITextView!
    @IBOutlet weak var likesText: UILabel!
    @IBOutlet weak var uploadtimeText: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var authorIMG: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        styleAuthorImageView()
        styleCaptionTextView()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }

        private func styleCaptionTextView() {
            captionTEXT.layer.borderColor = UIColor.lightGray.cgColor
            captionTEXT.layer.borderWidth = 1.0
            captionTEXT.layer.cornerRadius = 8.0
            captionTEXT.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
            captionTEXT.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }

        private func styleAuthorImageView() {
            authorIMG.layer.cornerRadius = authorIMG.frame.size.width / 2
            authorIMG.clipsToBounds = true
        }
}
