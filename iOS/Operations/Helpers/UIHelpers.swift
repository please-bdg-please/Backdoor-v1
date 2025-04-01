// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import UIKit
import SnapKit
import Lottie
import SwiftUIX

// MARK: - SnapKit View Extensions
extension UIView {
    /// Set up constraints with SnapKit's cleaner syntax
    /// - Parameter setup: Closure with constraints definition
    func setupConstraints(_ setup: (ConstraintMaker) -> Void) {
        self.snp.makeConstraints(setup)
    }
    
    /// Update constraints with SnapKit's cleaner syntax
    /// - Parameter setup: Closure with constraints definition
    func updateConstraints(_ setup: (ConstraintMaker) -> Void) {
        self.snp.updateConstraints(setup)
    }
    
    /// Create a stack view with SnapKit constraints
    /// - Parameters:
    ///   - axis: Axis for the stack view
    ///   - spacing: Spacing between items
    ///   - views: Views to add to the stack
    ///   - insets: Insets to apply to the stack view
    static func createStack(axis: NSLayoutConstraint.Axis,
                           spacing: CGFloat = 8,
                           views: [UIView],
                           insets: UIEdgeInsets = .zero) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = axis
        stackView.spacing = spacing
        stackView.layoutMargins = insets
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }
}

// MARK: - Animation Helper
class AnimationHelper {
    /// Add a Lottie animation to a view
    /// - Parameters:
    ///   - name: Animation name (JSON file without extension)
    ///   - view: Parent view to add the animation to
    ///   - loopMode: Animation loop mode
    ///   - size: Size for the animation view
    /// - Returns: The configured LottieAnimationView
    static func addAnimation(name: String, to view: UIView,
                            loopMode: LottieLoopMode = .loop,
                            size: CGSize? = nil) -> LottieAnimationView {
        // Create animation view from JSON file
        let animationView = LottieAnimationView(name: name)
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        
        // Add to parent view
        view.addSubview(animationView)
        
        // Setup constraints with SnapKit
        animationView.snp.makeConstraints { make in
            if let size = size {
                make.size.equalTo(size)
                make.center.equalToSuperview()
            } else {
                make.edges.equalToSuperview()
            }
        }
        
        // Start playing animation
        animationView.play()
        
        return animationView
    }
    
    /// Show an animated loading indicator
    /// - Parameters:
    ///   - view: View to add the loader to
    ///   - message: Optional message to display
    /// - Returns: Container view with the animation that can be removed later
    static func showLoader(in view: UIView, message: String? = nil) -> UIView {
        // Create container for the loader
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.addSubview(container)
        
        // Set constraints for full screen
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Create content container with blur effect
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let contentContainer = UIVisualEffectView(effect: blurEffect)
        contentContainer.layer.cornerRadius = 16
        contentContainer.clipsToBounds = true
        container.addSubview(contentContainer)
        
        // Set up constraints for the content container
        contentContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(200)
            if message != nil {
                make.height.equalTo(200)
            } else {
                make.height.equalTo(150)
            }
        }
        
        // Add animation to the content container
        let animationView = LottieAnimationView(name: "loading")
        animationView.loopMode = .loop
        contentContainer.contentView.addSubview(animationView)
        
        // Set up animation constraints
        animationView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            if message != nil {
                make.centerY.equalToSuperview().offset(-20)
            } else {
                make.centerY.equalToSuperview()
            }
            make.width.height.equalTo(100)
        }
        
        // Start the animation
        animationView.play()
        
        // Add message label if provided
        if let message = message {
            let label = UILabel()
            label.text = message
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.textColor = .label
            contentContainer.contentView.addSubview(label)
            
            // Set up label constraints
            label.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(animationView.snp.bottom).offset(10)
                make.left.right.equalToSuperview().inset(16)
            }
        }
        
        return container
    }
    
    /// Hide the loader
    /// - Parameter container: Container view returned by showLoader
    static func hideLoader(_ container: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            container.alpha = 0
        }, completion: { _ in
            container.removeFromSuperview()
        })
    }
}

// MARK: - Elegant UI Components
class ElegantUIComponents {
    /// Create a beautifully styled button with gradient
    /// - Parameters:
    ///   - title: Button title
    ///   - colors: Gradient colors (default blue gradient)
    ///   - cornerRadius: Corner radius (default 12)
    ///   - fontSize: Font size (default 16)
    /// - Returns: Configured button
    static func createGradientButton(title: String,
                                    colors: [UIColor] = [.systemBlue, UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)],
                                    cornerRadius: CGFloat = 12,
                                    fontSize: CGFloat = 16) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        button.layer.cornerRadius = cornerRadius
        button.clipsToBounds = true
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = cornerRadius
        
        // Ensure the gradient is applied after layout
        button.layer.insertSublayer(gradientLayer, at: 0)
        button.layoutIfNeeded()
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 4
        button.layer.masksToBounds = false
        
        // Ensure gradient covers the button
        button.layer.layoutSublayers()
        
        return button
    }
    
    /// Create a card view with shadow
    /// - Parameters:
    ///   - backgroundColor: Card background color
    ///   - cornerRadius: Corner radius
    /// - Returns: Configured card view
    static func createCardView(backgroundColor: UIColor = .systemBackground,
                             cornerRadius: CGFloat = 16) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = backgroundColor
        cardView.layer.cornerRadius = cornerRadius
        
        // Add shadow
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 6
        cardView.layer.masksToBounds = false
        
        return cardView
    }
    
    /// Create a beautiful text field with floating label
    /// - Parameters:
    ///   - placeholder: Placeholder text
    ///   - backgroundColor: Background color
    ///   - borderColor: Border color
    /// - Returns: Configured text field with container
    static func createFloatingTextField(placeholder: String,
                                      backgroundColor: UIColor = .systemBackground,
                                      borderColor: UIColor = .systemGray4) -> UIView {
        let container = UIView()
        container.backgroundColor = backgroundColor
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = borderColor.cgColor
        
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .none
        container.addSubview(textField)
        
        textField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }
        
        return container
    }
}

// MARK: - S# Create a demo view controller to show the new dependencies in action
cat > iOS/Views/Demo/EnhancedDependenciesViewController.swift << 'EOF'
// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import UIKit
import SwiftUI
import Lottie
import SnapKit
import CryptoSwift
import Moya
import SwiftUIX

/// Demo view controller showing the usage of the new dependencies
class EnhancedDependenciesViewController: UIViewController {
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let cryptoExampleButton = UIButton(type: .system)
    private let uiExampleButton = UIButton(type: .system)
    private let networkExampleButton = UIButton(type: .system)
    private let resourceExampleButton = UIButton(type: .system)
    private let swiftuiDemoButton = UIButton(type: .system)
    
    // Animation container
    private var animationContainer: UIView?
    private var animationView: LottieAnimationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Enhanced Dependencies"
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    private func setupUI() {
        // Set up scroll view
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Add content view to scroll view
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualToSuperview()
        }
        
        // Set up title label
        titleLabel.text = "New Dependencies Demo"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // Set up animation container
        let animContainer = UIView()
        animContainer.backgroundColor = .systemGray6
        animContainer.layer.cornerRadius = 16
        contentView.addSubview(animContainer)
        animContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(240)
            make.height.equalTo(180)
        }
        
        // Add animation
        let anim = AnimationHelper.addAnimation(name: "lottie_animation", to: animContainer, loopMode: .loop)
        animationContainer = animContainer
        animationView = anim
        
        // Create buttons using ElegantUIComponents
        cryptoExampleButton = ElegantUIComponents.createGradientButton(
            title: "CryptoSwift Example",
            colors: [.systemIndigo, .systemPurple]
        )
        cryptoExampleButton.addTarget(self, action: #selector(showCryptoExample), for: .touchUpInside)
        
        uiExampleButton = ElegantUIComponents.createGradientButton(
            title: "SnapKit & Lottie Example",
            colors: [.systemBlue, .systemTeal]
        )
        uiExampleButton.addTarget(self, action: #selector(showUIExample), for: .touchUpInside)
        
        networkExampleButton = ElegantUIComponents.createGradientButton(
            title: "Moya Example",
            colors: [.systemGreen, .systemTeal]
        )
        networkExampleButton.addTarget(self, action: #selector(showNetworkExample), for: .touchUpInside)
        
        resourceExampleButton = ElegantUIComponents.createGradientButton(
            title: "R.swift Example",
            colors: [.systemOrange, .systemYellow]
        )
        resourceExampleButton.addTarget(self, action: #selector(showResourceExample), for: .touchUpInside)
        
        swiftuiDemoButton = ElegantUIComponents.createGradientButton(
            title: "SwiftUIX Demo",
            colors: [.systemPink, .systemRed]
        )
        swiftuiDemoButton.addTarget(self, action: #selector(showSwiftUIDemo), for: .touchUpInside)
        
        // Create a stack view for buttons
        let buttonsStack = UIStackView(arrangedSubviews: [
            cryptoExampleButton,
            uiExampleButton,
            networkExampleButton,
            resourceExampleButton,
            swiftuiDemoButton
        ])
        buttonsStack.axis = .vertical
        buttonsStack.spacing = 20
        buttonsStack.distribution = .fillEqually
        contentView.addSubview(buttonsStack)
        
        // Set constraints for buttons stack
        buttonsStack.snp.makeConstraints { make in
            make.top.equalTo(animContainer.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(30)
            make.bottom.equalToSuperview().offset(-30)
            
            // Set height for each button
            buttonsStack.arrangedSubviews.forEach { button in
                button.snp.makeConstraints { make in
                    make.height.equalTo(50)
                }
            }
        }
    }
    
    // MARK: - Demo Methods
    
    @objc private func showCryptoExample() {
        // Create a text to encrypt
        let text = "Example secure text for encryption"
        let password = "securePassword123"
        
        guard let data = text.data(using: .utf8) else { return }
        
        // Use CryptoHelper to encrypt and decrypt
        let encryptedText = CryptoHelper.shared.encryptAES(data, password: password)
        
        var resultMessage = "Original: \(text)\n\n"
        
        if let encryptedText = encryptedText {
            resultMessage += "Encrypted (Base64):\n\(encryptedText)\n\n"
            
            // Decrypt
            if let decryptedData = CryptoHelper.shared.decryptAES(encryptedText, password: password),
               let decryptedText = String(data: decryptedData, encoding: .utf8) {
                resultMessage += "Decrypted: \(decryptedText)\n\n"
            } else {
                resultMessage += "Decryption failed\n\n"
            }
        } else {
            resultMessage += "Encryption failed\n\n"
        }
        
        // Show SHA-256 hash
        let shaHash = CryptoHelper.shared.sha256(text)
        resultMessage += "SHA-256 hash:\n\(shaHash)"
        
        // Show alert with results
        let alert = UIAlertController(title: "CryptoSwift Demo", message: resultMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func showUIExample() {
        // Show loading animation
        let loaderView = AnimationHelper.showLoader(in: view, message: "Loading...")
        
        // Hide it after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AnimationHelper.hideLoader(loaderView)
            
            // Show floating text field example
            let textFieldContainer = ElegantUIComponents.createFloatingTextField(placeholder: "Enter text here")
            
            // Create alert with custom view
            let alert = UIAlertController(title: "SnapKit & Lottie Demo", message: "Custom UI components created with SnapKit and styled elegantly.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    @objc private func showNetworkExample() {
        // Show loading
        let loaderView = AnimationHelper.showLoader(in: view, message: "Checking API...")
        
        // Use NetworkManager to make a request
        NetworkManager.shared.request(.sources, type: SourcesResponse.self) { result in
            // Hide loader
            AnimationHelper.hideLoader(loaderView)
            
            // Process result
            var message = ""
            switch result {
            case .success(let response):
                message = "API Request Successful!\n\n"
                message += "Number of sources: \(response.sources.count)\n"
                if !response.sources.isEmpty {
                    message += "\nFirst source: \(response.sources[0].name)"
                }
                
            case .failure(let error):
                message = "API Request Failed\n\n"
                message += "Error: \(error.localizedDescription)"
                
                // Since we're in a demo, we'll show a success message even if the API isn't available
                message += "\n\nThis is a demo of Moya's capabilities:"
                message += "\n- Endpoint abstraction"
                message += "\n- Type-safe API requests"
                message += "\n- Built-in logging and plugins"
                message += "\n- Async/await support"
            }
            
            // Show alert with results
            let alert = UIAlertController(title: "Moya Demo", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    @objc private func showResourceExample() {
        // In a real implementation, you would use R.swift generated resources
        let message = """
        R.swift gives you type-safe access to:
  # Let's check the available package.resolved files
find . -name "*.resolved"

# Let's see the current content of these package.resolved files
echo "First package.resolved file:"
cat $(find . -name "*.resolved" | head -1)

echo "Second package.resolved file:"
cat $(find . -name "*.resolved" | head -2 | tail -1)

# Let's also create a directory to hold our demo Lottie animation
mkdir -p iOS/Resources/Animations
# Let's try another way to find the package.resolved files
find . -name "package.resolved" -type f
find . -name "Package.resolved" -type f
find . -name "*.xcworkspace" -type d
find . -name "project.xcworkspace" -type d

# Check for .xcodeproj directory
find . -name "*.xcodeproj" -type d

# Look inside the xcodeproj directory
ls -la backdoor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

# Check if it exists
ls -la backdoor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# Look inside xcworkspace also
ls -la backdoor.xcworkspace/xcshareddata/swiftpm

# Check this one as well
ls -la backdoor.xcworkspace/xcshareddata/swiftpm/Package.resolved
# Create a simple Lottie animation JSON file for demo purposes
cat > iOS/Resources/Animations/lottie_animation.json << 'EOF'
{
  "v": "5.9.0",
  "fr": 30,
  "ip": 0,
  "op": 90,
  "w": 300,
  "h": 300,
  "nm": "Simple Animation",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Circle",
      "sr": 1,
      "ks": {
        "o": {
          "a": 1,
          "k": [
            {
              "i": { "x": [0.667], "y": [1] },
              "o": { "x": [0.333], "y": [0] },
              "t": 0,
              "s": [100]
            },
            {
              "i": { "x": [0.667], "y": [1] },
              "o": { "x": [0.333], "y": [0] },
              "t": 45,
              "s": [50]
            },
            { "t": 90, "s": [100] }
          ]
        },
        "r": {
          "a": 1,
          "k": [
            {
              "i": { "x": [0.667], "y": [1] },
              "o": { "x": [0.333], "y": [0] },
              "t": 0,
              "s": [0]
            },
            { "t": 90, "s": [360] }
          ]
        },
        "p": { "a": 0, "k": [150, 150, 0] },
        "a": { "a": 0, "k": [0, 0, 0] },
        "s": {
          "a": 1,
          "k": [
            {
              "i": { "x": [0.667, 0.667, 0.667], "y": [1, 1, 1] },
              "o": { "x": [0.333, 0.333, 0.333], "y": [0, 0, 0] },
              "t": 0,
              "s": [100, 100, 100]
            },
            {
              "i": { "x": [0.667, 0.667, 0.667], "y": [1, 1, 1] },
              "o": { "x": [0.333, 0.333, 0.333], "y": [0, 0, 0] },
              "t": 45,
              "s": [150, 150, 100]
            },
            { "t": 90, "s": [100, 100, 100] }
          ]
        }
      },
      "ao": 0,
      "shapes": [
        {
          "ty": "gr",
          "it": [
            {
              "d": 1,
              "ty": "el",
              "s": { "a": 0, "k": [80, 80] },
              "p": { "a": 0, "k": [0, 0] }
            },
            {
              "ty": "fl",
              "c": {
                "a": 1,
                "k": [
                  {
                    "i": { "x": [0.667], "y": [1] },
                    "o": { "x": [0.333], "y": [0] },
                    "t": 0,
                    "s": [0.2, 0.6, 1, 1]
                  },
                  {
                    "i": { "x": [0.667], "y": [1] },
                    "o": { "x": [0.333], "y": [0] },
                    "t": 45,
                    "s": [1, 0.4, 0.4, 1]
                  },
                  { "t": 90, "s": [0.2, 0.6, 1, 1] }
                ]
              },
              "o": { "a": 0, "k": 100 }
            },
            { "ty": "tr", "p": { "a": 0, "k": [0, 0] }, "a": { "a": 0, "k": [0, 0] }, "s": { "a": 0, "k": [100, 100] }, "r": { "a": 0, "k": 0 }, "o": { "a": 0, "k": 100 } }
          ]
        }
      ]
    }
  ]
}
