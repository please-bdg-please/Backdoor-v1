// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import UIKit
import SnapKit
import Lottie

// MARK: - UIView Extensions with SnapKit
extension UIView {
    /// Add and setup constraints for a child view in a single call
    /// - Parameters:
    ///   - child: Child view to add
    ///   - setup: Closure for configuring constraints
    func addSubviewWithConstraints(_ child: UIView, setup: (ConstraintMaker) -> Void) {
        addSubview(child)
        child.setupConstraints(setup)
    }
    
    /// Create a stack of views with equal spacing
    /// - Parameters:
    ///   - views: Views to include in the stack
    ///   - axis: Stack axis (horizontal or vertical)
    ///   - spacing: Spacing between views
    ///   - distribution: Distribution type
    ///   - alignment: Alignment type
    /// - Returns: Configured stack view
    func createStack(
        with views: [UIView],
        axis: NSLayoutConstraint.Axis,
        spacing: CGFloat = 8,
        distribution: UIStackView.Distribution = .fill,
        alignment: UIStackView.Alignment = .fill
    ) -> UIStackView {
        let stack = UIView.createStack(
            axis: axis,
            spacing: spacing,
            views: views,
            insets: .zero
        )
        stack.distribution = distribution
        stack.alignment = alignment
        return stack
    }
    
    /// Add a loading indicator with optional text
    /// - Parameters:
    ///   - text: Optional loading text
    ///   - style: Activity indicator style
    /// - Returns: The container view that can be removed later
    func addLoadingIndicator(text: String? = nil, style: UIActivityIndicatorView.Style = .large) -> UIView {
        return AnimationHelper.showLoader(in: self, message: text)
    }
    
    /// Add a Lottie animation as a child view
    /// - Parameters:
    ///   - name: Animation JSON name
    ///   - loopMode: Animation loop mode
    ///   - size: Optional fixed size for animation
    /// - Returns: The configured animation view
    func addLottieAnimation(name: String, loopMode: LottieLoopMode = .loop, size: CGSize? = nil) -> LottieAnimationView {
        return AnimationHelper.addAnimation(name: name, to: self, loopMode: loopMode, size: size)
    }
    
    /// Apply elegant card styling to the view
    /// - Parameters:
    ///   - cornerRadius: Corner radius for the card
    ///   - shadowOpacity: Shadow opacity (0-1)
    ///   - backgroundColor: Background color
    func applyCardStyling(
        cornerRadius: CGFloat = 16,
        shadowOpacity: Float = 0.1,
        backgroundColor: UIColor = .systemBackground
    ) {
        self.backgroundColor = backgroundColor
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = 6
    }
    
    /// Add a gradient background to the view
    /// - Parameters:
    ///   - colors: Gradient colors
    ///   - startPoint: Start point (default top-left)
    ///   - endPoint: End point (default bottom-right)
    func addGradientBackground(
        colors: [UIColor] = [.systemBlue, UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        // Remove any existing gradient
        layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
        
        // Insert at index 0 to be below other sublayers
        layer.insertSublayer(gradientLayer, at: 0)
        
        // Make sure gradient updates when view is resized
        layoutIfNeeded()
    }
    
    /// Apply futuristic shadow effect to the view
    func applyFuturisticShadow() {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.systemBlue.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 8
    }
}

// MARK: - UIButton Extensions
extension UIButton {
    /// Convert a standard UIButton to a gradient button
    /// - Parameters:
    ///   - colors: Gradient colors
    ///   - startPoint: Start point of gradient
    ///   - endPoint: End point of gradient
    func convertToGradientButton(
        colors: [UIColor] = [.systemBlue, UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        // Store original title color and background color
        let titleColor = titleColor(for: .normal) ?? .white
        
        // Create a new button using ElegantUIComponents
        let newButton = ElegantUIComponents.createGradientButton(
            title: title(for: .normal) ?? "",
            colors: colors,
            cornerRadius: layer.cornerRadius,
            fontSize: titleLabel?.font.pointSize ?? 16
        )
        
        // Copy properties from the original button
        setTitle(newButton.title(for: .normal), for: .normal)
        setTitleColor(titleColor, for: .normal)
        
        // Add gradient background
        addGradientBackground(colors: colors, startPoint: startPoint, endPoint: endPoint)
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        layer.masksToBounds = false
    }
}

// MARK: - UIViewController Extensions
extension UIViewController {
    /// Show a loading overlay with Lottie animation
    /// - Parameters:
    ///   - message: Optional loading message
    ///   - animationName: Name of Lottie animation
    /// - Returns: The container view that can be removed later
    func showLoadingOverlay(message: String? = R.string.general.loading, animationName: String = "loading") -> UIView {
        return AnimationHelper.showLoader(in: view, message: message)
    }
    
    /// Hide the loading overlay
    /// - Parameter overlay: The overlay container view returned by showLoadingOverlay
    func hideLoadingOverlay(_ overlay: UIView) {
        AnimationHelper.hideLoader(overlay)
    }
    
    /// Show a brief success animation
    /// - Parameter message: Optional success message
    func showSuccessAnimation(message: String? = nil) {
        let animationView = view.addLottieAnimation(
            name: "success",
            loopMode: .playOnce,
            size: CGSize(width: 200, height: 200)
        )
        
        // Center the animation
        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 200, height: 200))
        }
        
        // Add message label if provided
        if let message = message {
            let label = UILabel()
            label.text = message
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.textColor = .label
            view.addSubview(label)
            
            label.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(animationView.snp.bottom).offset(8)
            }
            
            // Remove label after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                label.removeFromSuperview()
            }
        }
        
        // Remove animation after playing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            animationView.removeFromSuperview()
        }
    }
}

// MARK: - CALayer Extensions
extension CALayer {
    /// Apply a futuristic shadow to the layer
    func applyFuturisticShadow() {
        masksToBounds = false
        shadowColor = UIColor.systemBlue.cgColor
        shadowOffset = CGSize(width: 0, height: 4)
        shadowOpacity = 0.2
        shadowRadius = 8
    }
}
