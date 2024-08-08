//
//  MessageTableViewCell.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/10/24.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    let messageLabel = UILabel()
        let bubbleBackgroundView = UIView()
        
        var isIncoming: Bool = false {
            didSet {
                bubbleBackgroundView.backgroundColor = isIncoming ? .incomingMessageBubbleColor : .outgoingMessageBubbleColor
                messageLabel.textColor = isIncoming ? .incomingMessageTextColor : .outgoingMessageTextColor
                
                if isIncoming {
                    messageLabel.textAlignment = .left
                    leadingConstraint.isActive = true
                    trailingConstraint.isActive = false
                } else {
                    messageLabel.textAlignment = .right
                    leadingConstraint.isActive = false
                    trailingConstraint.isActive = true
                }
            }
        }

        var leadingConstraint: NSLayoutConstraint!
        var trailingConstraint: NSLayoutConstraint!

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            setupViews()
            setupConstraints()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupViews()
            setupConstraints()
        }

        private func setupViews() {
            bubbleBackgroundView.layer.cornerRadius = 16
            bubbleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bubbleBackgroundView)

            messageLabel.numberOfLines = 0
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(messageLabel)
        }

        private func setupConstraints() {
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
                messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
                messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250),

                bubbleBackgroundView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -8),
                bubbleBackgroundView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor, constant: -16),
                bubbleBackgroundView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
                bubbleBackgroundView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 16)
            ])
            leadingConstraint = messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32)
            trailingConstraint = messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)

            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
        }
}

extension UIColor {
    static let incomingMessageBubbleColor = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.2, alpha: 1.0) : UIColor(white: 0.9, alpha: 1.0)
    }
    
    static let outgoingMessageBubbleColor = UIColor { _ in
        return UIColor.systemBlue
    }
    
    static let incomingMessageTextColor = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
    }
    
    static let outgoingMessageTextColor = UIColor.white
}
