// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import UIKit
import SnapKit

class UserMessageCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear

        // Create the bubble view
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        
        // Add gradient to bubble for a more modern look
        bubbleView.addGradientBackground(
            colors: [
                UIColor.systemBlue,
                UIColor(red: 0.1, green: 0.6, blue: 1.0, alpha: 1.0)
            ],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
        
        // Add subtle shadow for depth
        bubbleView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 2)
        bubbleView.layer.shadowRadius = 4
        bubbleView.layer.shadowOpacity = 0.5
        bubbleView.layer.masksToBounds = false

        // Configure message label
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 16)

        // Add subviews
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        // Setup constraints with SnapKit
        bubbleView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.width.lessThanOrEqualTo(280)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(bubbleView).offset(12)
            make.trailing.equalTo(bubbleView).offset(-12)
            make.top.equalTo(bubbleView).offset(8)
            make.bottom.equalTo(bubbleView).offset(-8)
        }
    }

    func configure(with message: ChatMessage) {
        messageLabel.text = message.content
    }
}
