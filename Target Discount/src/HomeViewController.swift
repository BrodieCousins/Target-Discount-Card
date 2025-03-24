import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    private var traitRegistration: NSObjectProtocol?
    
    // MARK: - UI Elements
    
    private let logoView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "targetLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Discount Scanner"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let illustrationView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.brandGradientStart.withAlphaComponent(0.05)
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let barcodeIcon: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Scan and display your team member\ndiscount card with ease."
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let viewBarcodeButton = GradientButton(type: .system)
    private let scanBarcodeButton = SecondaryButton(type: .system)
    
    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "This is not an official Target™ application.\nFor team member use only."
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.textSecondary.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "Version 1.0.0"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.textSecondary.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateColorsForCurrentMode()
        setupTraitChangeObserving()
        edgesForExtendedLayout = .all
        navigationController?.isNavigationBarHidden = true
        
        // Register for app foreground notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateOnForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Register for barcode deletion notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAfterBarcodeDeletion),
            name: NSNotification.Name("BarcodeDeleted"),
            object: nil
        )
    }
    
    @objc private func updateOnForeground() {
        // Force button state update whenever app comes to foreground
        DispatchQueue.main.async {
            self.updateButtonStates()
        }
    }
    
    @objc private func updateAfterBarcodeDeletion() {
        // Always update button states on main thread
        DispatchQueue.main.async {
            self.updateButtonStates()
        }
    }
    
    deinit {
        // Clean up notification observers
        NotificationCenter.default.removeObserver(self)
        
        if let registration = traitRegistration {
            NotificationCenter.default.removeObserver(registration)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Always update button states when view appears
        updateButtonStates()
        
        // Update colors for current appearance mode
        updateColorsForCurrentMode()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update button styling after layout is complete
        updateButtonStates()
        
        // Force barcode icon corner radius update
        for subview in barcodeIcon.subviews {
            if subview.layer.borderWidth > 0 {
                subview.layer.cornerRadius = 4
            }
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Set background color
        view.backgroundColor = .white
        
        // Configure logo
        logoView.translatesAutoresizingMaskIntoConstraints = false
        
        // Force title to be visible with contrasting color
        titleLabel.text = "Discount Scanner"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black // Force a visible color initially
        
        // Configure buttons
        viewBarcodeButton.setTitle("View Saved Barcode", for: .normal)
        viewBarcodeButton.translatesAutoresizingMaskIntoConstraints = false
        viewBarcodeButton.addTarget(self, action: #selector(viewBarcodeButtonTapped), for: .touchUpInside)
        
        scanBarcodeButton.setTitle("Scan New Barcode", for: .normal)
        scanBarcodeButton.translatesAutoresizingMaskIntoConstraints = false
        scanBarcodeButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        
        // Create barcode icon in illustration view
        setupBarcodeIcon()
        
        // Add subviews
        view.addSubview(logoView)
        view.addSubview(titleLabel)
        view.addSubview(illustrationView)
        illustrationView.addSubview(barcodeIcon)
        view.addSubview(descriptionLabel)
        view.addSubview(viewBarcodeButton)
        view.addSubview(scanBarcodeButton)
        view.addSubview(disclaimerLabel)
        view.addSubview(versionLabel)
        
        // Ensure title is above other views in Z-order
        view.bringSubviewToFront(titleLabel)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Logo
            logoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            logoView.widthAnchor.constraint(equalToConstant: 40),
            logoView.heightAnchor.constraint(equalToConstant: 40),
            
            // Title - ensure proper constraints
            titleLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // Illustration View
            illustrationView.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 30),
            illustrationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            illustrationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            illustrationView.heightAnchor.constraint(equalToConstant: 190),
            
            // Barcode Icon
            barcodeIcon.centerXAnchor.constraint(equalTo: illustrationView.centerXAnchor),
            barcodeIcon.centerYAnchor.constraint(equalTo: illustrationView.centerYAnchor),
            barcodeIcon.widthAnchor.constraint(equalToConstant: 120),
            barcodeIcon.heightAnchor.constraint(equalToConstant: 60),
            
            // Description Label
            descriptionLabel.topAnchor.constraint(equalTo: illustrationView.bottomAnchor, constant: 30),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // View Barcode Button
            viewBarcodeButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            viewBarcodeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            viewBarcodeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            viewBarcodeButton.heightAnchor.constraint(equalToConstant: 64),
            
            // Scan Barcode Button
            scanBarcodeButton.topAnchor.constraint(equalTo: viewBarcodeButton.bottomAnchor, constant: 16),
            scanBarcodeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            scanBarcodeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            scanBarcodeButton.heightAnchor.constraint(equalToConstant: 64),
            
            // Disclaimer Label
            disclaimerLabel.topAnchor.constraint(equalTo: scanBarcodeButton.bottomAnchor, constant: 36),
            disclaimerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            disclaimerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Version Label
            versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Set minimum width for the title to ensure it's visible
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private func setupBarcodeIcon() {
        // Remove existing content
        barcodeIcon.subviews.forEach { $0.removeFromSuperview() }
        
        // Create a UIImageView for the barcode icon
        let barcodeImageView = UIImageView()
        barcodeImageView.translatesAutoresizingMaskIntoConstraints = false
        barcodeImageView.contentMode = .scaleAspectFit
        barcodeImageView.image = createCenteredBarcodeIcon()
        
        // Add to the main view
        barcodeIcon.addSubview(barcodeImageView)
        
        // Center and size constraints
        NSLayoutConstraint.activate([
            barcodeImageView.centerXAnchor.constraint(equalTo: barcodeIcon.centerXAnchor),
            barcodeImageView.centerYAnchor.constraint(equalTo: barcodeIcon.centerYAnchor),
            barcodeImageView.widthAnchor.constraint(equalTo: barcodeIcon.widthAnchor, multiplier: 0.9),
            barcodeImageView.heightAnchor.constraint(equalTo: barcodeIcon.heightAnchor, multiplier: 0.9)
        ])
    }
    
    // Helper method to create the barcode icon as an image
    private func createCenteredBarcodeIcon() -> UIImage {
        let size = CGSize(width: 120, height: 60)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        // Draw the rectangle border
        let rectangle = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: 4)
        UIColor.brandGradientStart.setStroke()
        rectangle.lineWidth = 3
        rectangle.stroke()
        
        // Define barcode lines
        let lineWidths: [CGFloat] = [2, 4, 2, 5, 3, 2, 4, 2, 5, 3, 2, 5, 3, 2, 4, 3]
        let totalLinesWidth = lineWidths.reduce(0, +)
        let spaceBetweenLines: CGFloat = 2
        let numberOfGaps = lineWidths.count - 1
        let totalWidth = totalLinesWidth + (spaceBetweenLines * CGFloat(numberOfGaps))
        
        // Calculate starting position to center the barcode
        let startX = (size.width - totalWidth) / 2
        
        // Draw lines
        var currentX = startX
        UIColor.brandGradientStart.setFill()
        
        for width in lineWidths {
            let barRect = CGRect(x: currentX, y: 10, width: width, height: size.height - 20)
            UIRectFill(barRect)
            currentX += width + spaceBetweenLines
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
    
    // MARK: - Trait Change Handling
    
    private func setupTraitChangeObserving() {
        if #available(iOS 17.0, *) {
            traitRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (vc: HomeViewController, _: UITraitCollection) in
                guard let self = self else { return }
                self.updateColorsForCurrentMode()
            }
        }
    }
    
    @available(iOS, deprecated: 17.0, message: "Use the trait change registration APIs")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 17.0, *) {
            // Using the registration API for iOS 17+
        } else {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateColorsForCurrentMode()
            }
        }
    }
    
    private func updateColorsForCurrentMode() {
        // Update colors based on light/dark mode
        if #available(iOS 13.0, *) {
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            
            // Background colors
            view.backgroundColor = isDarkMode ? UIColor(white: 0.1, alpha: 1.0) : .white
            illustrationView.backgroundColor = isDarkMode ? UIColor.brandGradientStart.withAlphaComponent(0.1) : UIColor.brandGradientStart.withAlphaComponent(0.05)
            
            // Text colors
            titleLabel.textColor = isDarkMode ? .white : .textPrimary
            descriptionLabel.textColor = isDarkMode ? UIColor(white: 0.8, alpha: 1.0) : .textSecondary
            disclaimerLabel.textColor = isDarkMode ? UIColor.white.withAlphaComponent(0.6) : UIColor.textSecondary.withAlphaComponent(0.6)
            versionLabel.textColor = isDarkMode ? UIColor.white.withAlphaComponent(0.5) : UIColor.textSecondary.withAlphaComponent(0.5)
            
            // Navigation bar
            navigationController?.navigationBar.tintColor = isDarkMode ? .white : .textPrimary
            navigationController?.navigationBar.barStyle = isDarkMode ? .black : .default
        }
    }
    
    // MARK: - Button State Management
    
    private func updateButtonStates() {
        let hasSavedBarcode = BarcodeManager.shared.hasStoredBarcode()
        
        // Detect current style state
        let viewHasGradient = viewBarcodeButton.layer.sublayers?.contains(where: { $0 is CAGradientLayer }) ?? false
        let scanHasGradient = scanBarcodeButton.layer.sublayers?.contains(where: { $0 is CAGradientLayer }) ?? false
        
        // Set button corner radius (only need to do this once)
        viewBarcodeButton.layer.cornerRadius = viewBarcodeButton.frame.height / 2
        scanBarcodeButton.layer.cornerRadius = scanBarcodeButton.frame.height / 2
        viewBarcodeButton.clipsToBounds = true
        scanBarcodeButton.clipsToBounds = true
        
        if hasSavedBarcode {
            // PRIMARY: View Barcode Button
            if !viewHasGradient {
                // Only update style if needed
                viewBarcodeButton.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
                applyPrimaryStyle(to: viewBarcodeButton)
            }
            viewBarcodeButton.isEnabled = true
            viewBarcodeButton.alpha = 1.0
            
            // SECONDARY: Scan Button
            if scanHasGradient {
                // Only update style if needed
                scanBarcodeButton.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
                applySecondaryStyle(to: scanBarcodeButton)
            }
            scanBarcodeButton.isEnabled = true
            scanBarcodeButton.alpha = 1.0
        } else {
            // PRIMARY: Scan Button
            if !scanHasGradient {
                // Only update style if needed
                scanBarcodeButton.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
                applyPrimaryStyle(to: scanBarcodeButton)
            }
            scanBarcodeButton.isEnabled = true
            scanBarcodeButton.alpha = 1.0
            
            // SECONDARY: View Button (disabled)
            if viewHasGradient {
                // Only update style if needed
                viewBarcodeButton.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
                applySecondaryStyle(to: viewBarcodeButton)
            }
            viewBarcodeButton.isEnabled = false
            viewBarcodeButton.alpha = 0.6
        }
    }

    private func applyPrimaryStyle(to button: UIButton) {
        // Apply gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = button.bounds
        gradientLayer.colors = [UIColor.brandGradientStart.cgColor, UIColor.brandGradientEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = button.frame.height / 2
        button.layer.insertSublayer(gradientLayer, at: 0)
        
        // Set title color AFTER gradient is applied
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    }

    private func applySecondaryStyle(to button: UIButton) {
        button.backgroundColor = .lightGray
        button.setTitleColor(.darkText, for: .normal)  // Dark text instead of grey
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
    }
    
    // MARK: - Actions
    
    @objc private func scanButtonTapped() {
        let scannerVC = BarcodeScannerViewController()
        navigationController?.pushViewController(scannerVC, animated: true)
    }
    
    @objc private func viewBarcodeButtonTapped() {
        if BarcodeManager.shared.hasStoredBarcode() {
            let barcodeVC = BarcodeViewController()
            navigationController?.pushViewController(barcodeVC, animated: true)
        }
    }
}
