//
//  ChatTableViewCell.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/9/24.
//


import UIKit

class ChatTableViewCell: UITableViewCell {
    @IBOutlet weak var chatPFP: UIImageView!
    @IBOutlet weak var chatName: UILabel!
    @IBOutlet weak var chatLastSeen: UILabel!
    @IBOutlet weak var chatLastTStamp: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupImageView()
    }

    private func setupImageView() {
        chatPFP.layer.cornerRadius = chatPFP.frame.size.width / 2
        chatPFP.clipsToBounds = true
        chatPFP.contentMode = .scaleAspectFill
    }
}
