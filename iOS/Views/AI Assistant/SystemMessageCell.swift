// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import CoreData
import UIKit
import SnapKit
import Lottie

class SystemMessageCell: UITableViewCell {
    private let messageLabel = UILabel()
    private let containerView = UIView()
    private var animationView: LottieAnimationView?

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
        
        // Add a container view for better visual grouping and animations
        containerView.backgroundColor = .clear
        contentView.addSubview(containerView)
        
        // Configure message label
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .systemGray
        messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        messageLabel.textAlignment = .center
        
        containerView.addSubview(messageLabel)

        // Setup constraints with SnapKit
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(3)
            make.bottom.equalToSuperview().offset(-3)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(12)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
            make.top.equalToSuperview().offset(3)
            make.bottom.equalToSuperview().offset(-3)
        }
    }

    func configure(with message: ChatMessage) {
        // Clear any existing animation
        clearAnimation()
        
        // Process the message content
        let content = message.content ?? ""
        
        // Handle different system message types with specialized styling
        if content.contains("error") || content.contains("failed") || content.contains("Error:") {
            // Style for error messages
            messageLabel.textColor = .systemRed
            messageLabel.text = content
            
            // Add error animation
            addAnimation(name: "error", tintColor: .systemRed)
            
        } else if content.contains("success") || content.contains("completed") {
            // Style for success messages
            messageLabel.textColor = .systemGreen
            messageLabel.text = content
            
            // Add success animation
            addAnimation(name: "success", tintColor: .systemGreen)
            
        } else if content == "Assistant is thinking..." {
            // This should be handled by AIMessageCell, but just in case
            messageLabel.textColor = .systemGray
            messageLabel.text = content
            
        } else {
            // Default styling
            messageLabel.textColor = .systemGray
            messageLabel.text = content
        }
    }
    
    private func addAnimation(name: String, tintColor: UIColor) {
        // Create small animation to enhance the message
        animationView = LottieAnimationView(name: name)
        animationView?.loopMode = .playOnce
        animationView?.contentMode = .scaleAspectFit
        
        if let animationView = animationView {
            containerView.addSubview(animationView)
            
            // Position animation next to the text
            animationView.snp.makeConstraints { make in
                make.leading.equalTo(messageLabel.snp.trailing).offset(4)
                make.centerY.equalTo(messageLabel)
                make.width.height.equalTo(20)
            }
            
            // Set animation tint color
            let colorProvider = ColorValueProvider(tintColor.lottieColorValue)
            let keyPath = AnimationKeypath(keys: ["**", "Fill 1", "**", "Color"])
            animationView.setValueProvider(colorProvider, keypath: keyPath)
            
            // Play animation
            animationView.play()
        }
    }
    
    private func clearAnimation() {
        // Remove animation view if exists
        animationView?.removeFromSuperview()
        animationView = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        clearAnimation()
        messageLabel.textColor = .systemGray
    }
}
