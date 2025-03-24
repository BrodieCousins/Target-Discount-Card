import UIKit

extension UIColor {
    // Main brand colors
    static let brandGradientStart = UIColor(red: 0/255, green: 191/255, blue: 209/255, alpha: 1.0) // #00BFD1
    static let brandGradientEnd = UIColor(red: 51/255, green: 217/255, blue: 166/255, alpha: 1.0) // #33D9A6
    
    // Helper colors
    static let deleteRed = UIColor(red: 255/255, green: 77/255, blue: 79/255, alpha: 1.0) // #FF4D4F
    static let deleteBackground = UIColor(red: 255/255, green: 242/255, blue: 240/255, alpha: 1.0) // #FFF2F0
    static let lightGray = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0) // #F5F5F5
    static let textPrimary = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0) // #222222
    static let textSecondary = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1.0) // #555555
    static let brightYellow = UIColor(red: 255/255, green: 221/255, blue: 102/255, alpha: 1.0) // #FFDD66
}

extension UIView {
    // Add gradient to any view
    func applyGradient(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0.5), endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) {
        // First check if there's already a gradient layer
        if let existingGradient = layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            // Update existing gradient instead of creating a new one
            existingGradient.colors = colors.map { $0.cgColor }
            existingGradient.startPoint = startPoint
            existingGradient.endPoint = endPoint
            existingGradient.frame = bounds
        } else {
            // Create a new gradient layer if none exists
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = bounds
            gradientLayer.colors = colors.map { $0.cgColor }
            gradientLayer.startPoint = startPoint
            gradientLayer.endPoint = endPoint
            layer.insertSublayer(gradientLayer, at: 0)
        }
    }
    
    // Apply the app's standard gradient
    func applyBrandGradient() {
        applyGradient(colors: [.brandGradientStart, .brandGradientEnd])
    }
    
    // Add rounded corners to any view
    func roundCorners(radius: CGFloat = 12) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
    
    // Add shadow to any view
    func addShadow(opacity: Float = 0.1, radius: CGFloat = 4, offset: CGSize = CGSize(width: 0, height: 2)) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.masksToBounds = false
    }
}

// Custom gradient button
class GradientButton: UIButton {
    // Store the gradient layer so we only create it once
    private var gradientLayer: CAGradientLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Create gradient layer only once or update existing one
        if gradientLayer == nil {
            gradientLayer = CAGradientLayer()
            gradientLayer!.colors = [UIColor.brandGradientStart.cgColor, UIColor.brandGradientEnd.cgColor]
            gradientLayer!.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer!.endPoint = CGPoint(x: 1, y: 0.5)
            layer.insertSublayer(gradientLayer!, at: 0)
        }
        
        // Just update frame and corner radius rather than recreating
        gradientLayer!.frame = bounds
        gradientLayer!.cornerRadius = bounds.height / 2
        
        // Set other properties
        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}

// Custom secondary button
class SecondaryButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .lightGray
        setTitleColor(.textSecondary, for: .normal)
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
        titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    }
}

// Card view with shadow
class CardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 12
        addShadow()
    }
}
