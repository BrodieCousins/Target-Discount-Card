import UIKit
import CoreImage

class BarcodeViewController: UIViewController {
    
    // MARK: - Properties
    
    private var brightnessBeforeShow: CGFloat = 0
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
        label.text = "Team Member Discount"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gradientLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Present barcode at checkout"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let barcodeContainerView: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let barcodeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let barcodeNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let brightnessContainerView: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let brightnessLabel: UILabel = {
        let label = UILabel()
        label.text = "Screen Brightness"
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let brightnessDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Auto-increased for better scanning"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.textSecondary.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let brightnessSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = Float(UIScreen.main.brightness)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let minBrightnessIcon: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            imageView.image = UIImage(systemName: "sun.min")
            imageView.tintColor = UIColor.textSecondary.withAlphaComponent(0.5)
        }
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let maxBrightnessIcon: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            imageView.image = UIImage(systemName: "sun.max")
            imageView.tintColor = UIColor.brightYellow
        }
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Barcode", for: .normal)
        button.setTitleColor(.deleteRed, for: .normal)
        button.backgroundColor = .deleteBackground
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 28
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "This is not an official Target™ application.\nFor team member use only."
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.textSecondary.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBrightnessControl()
        updateColorsForCurrentMode()
        setupTraitChangeObserving()
        
        // Update brightness container height - use only ONE constraint
        // Remove any previous constraints to be safe
        brightnessContainerView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                brightnessContainerView.removeConstraint(constraint)
            }
        }
        
        // Add a single new constraint
        brightnessContainerView.heightAnchor.constraint(equalToConstant: 130).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        // Store current brightness
        brightnessBeforeShow = UIScreen.main.brightness
        
        // Auto-increase brightness for better scanning
        UIScreen.main.brightness = 0.9
        brightnessSlider.value = Float(UIScreen.main.brightness)
        
        // Display barcode
        displayBarcode()
        
        // Add subtle animation
        addPulseAnimation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Update colors for current appearance mode
        updateColorsForCurrentMode()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Force barcode number to be visible with proper color
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                barcodeNumberLabel.textColor = .white
            } else {
                barcodeNumberLabel.textColor = .black
            }
        } else {
            barcodeNumberLabel.textColor = .black
        }
        
        // Update UI elements sizing
        deleteButton.layer.cornerRadius = deleteButton.bounds.height / 2
        
        // Ensure brightness slider has proper colors
        brightnessSlider.tintColor = .brandGradientStart
        
        // Reset gradient line if needed
        if gradientLine.layer.sublayers?.contains(where: { $0 is CAGradientLayer }) != true {
            gradientLine.applyBrandGradient()
            gradientLine.alpha = 0.3
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Restore original brightness
        UIScreen.main.brightness = brightnessBeforeShow
    }
    
    deinit {
        if let registration = traitRegistration {
            NotificationCenter.default.removeObserver(registration)
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Set background color
        view.backgroundColor = .white
        
        // Configure navigation bar
        navigationItem.hidesBackButton = true
        if #available(iOS 13.0, *) {
            let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
            navigationItem.leftBarButtonItem = backButton
        } else {
            let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
            navigationItem.leftBarButtonItem = backButton
        }
        
        // Apply gradient to gradient line
        gradientLine.applyBrandGradient()
        gradientLine.alpha = 0.3
        
        // Configure slider tint
        brightnessSlider.tintColor = .brandGradientStart
        
        // Add subviews
        view.addSubview(logoView)
        view.addSubview(titleLabel)
        view.addSubview(gradientLine)
        view.addSubview(instructionLabel)
        view.addSubview(barcodeContainerView)
        barcodeContainerView.addSubview(barcodeImageView)
        barcodeContainerView.addSubview(barcodeNumberLabel)
        
        view.addSubview(brightnessContainerView)
        brightnessContainerView.addSubview(brightnessLabel)
        brightnessContainerView.addSubview(brightnessDescriptionLabel)
        brightnessContainerView.addSubview(brightnessSlider)
        brightnessContainerView.addSubview(minBrightnessIcon)
        brightnessContainerView.addSubview(maxBrightnessIcon)
        
        view.addSubview(deleteButton)
        view.addSubview(disclaimerLabel)
        
        // Add button actions
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Logo
            logoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), // Reduced from 20
            logoView.widthAnchor.constraint(equalToConstant: 32),
            logoView.heightAnchor.constraint(equalToConstant: 32),
            
            // Title
            titleLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
            
            // Gradient Line
            gradientLine.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 16),
            gradientLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientLine.heightAnchor.constraint(equalToConstant: 4),
            
            // Instruction Label
            instructionLabel.topAnchor.constraint(equalTo: gradientLine.bottomAnchor, constant: 24),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Barcode Container
            barcodeContainerView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            barcodeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            barcodeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            barcodeContainerView.heightAnchor.constraint(equalToConstant: 260),
            
            // Barcode Image
            barcodeImageView.topAnchor.constraint(equalTo: barcodeContainerView.topAnchor, constant: 30),
            barcodeImageView.centerXAnchor.constraint(equalTo: barcodeContainerView.centerXAnchor),
            barcodeImageView.widthAnchor.constraint(equalTo: barcodeContainerView.widthAnchor, multiplier: 0.8),
            barcodeImageView.heightAnchor.constraint(equalToConstant: 140),
            
            // Barcode Number
            barcodeNumberLabel.topAnchor.constraint(equalTo: barcodeImageView.bottomAnchor, constant: 30),
            barcodeNumberLabel.centerXAnchor.constraint(equalTo: barcodeContainerView.centerXAnchor),
            barcodeNumberLabel.leadingAnchor.constraint(equalTo: barcodeContainerView.leadingAnchor, constant: 20),
            barcodeNumberLabel.trailingAnchor.constraint(equalTo: barcodeContainerView.trailingAnchor, constant: -20),
            
            // Brightness Container - height set in viewDidLoad
            brightnessContainerView.topAnchor.constraint(equalTo: barcodeContainerView.bottomAnchor, constant: 30),
            brightnessContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            brightnessContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Brightness Label
            brightnessLabel.topAnchor.constraint(equalTo: brightnessContainerView.topAnchor, constant: 16),
            brightnessLabel.leadingAnchor.constraint(equalTo: brightnessContainerView.leadingAnchor, constant: 20),
            
            // Brightness Description
            brightnessDescriptionLabel.topAnchor.constraint(equalTo: brightnessLabel.bottomAnchor, constant: 4),
            brightnessDescriptionLabel.leadingAnchor.constraint(equalTo: brightnessContainerView.leadingAnchor, constant: 20),
            
            // Min Brightness Icon
            minBrightnessIcon.leadingAnchor.constraint(equalTo: brightnessContainerView.leadingAnchor, constant: 20),
            minBrightnessIcon.bottomAnchor.constraint(equalTo: brightnessContainerView.bottomAnchor, constant: -16),
            minBrightnessIcon.widthAnchor.constraint(equalToConstant: 16),
            minBrightnessIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Slider
            brightnessSlider.leadingAnchor.constraint(equalTo: minBrightnessIcon.trailingAnchor, constant: 12),
            brightnessSlider.trailingAnchor.constraint(equalTo: maxBrightnessIcon.leadingAnchor, constant: -12),
            brightnessSlider.centerYAnchor.constraint(equalTo: minBrightnessIcon.centerYAnchor),
            
            // Max Brightness Icon
            maxBrightnessIcon.trailingAnchor.constraint(equalTo: brightnessContainerView.trailingAnchor, constant: -20),
            maxBrightnessIcon.centerYAnchor.constraint(equalTo: minBrightnessIcon.centerYAnchor),
            maxBrightnessIcon.widthAnchor.constraint(equalToConstant: 22),
            maxBrightnessIcon.heightAnchor.constraint(equalToConstant: 22),
            
            // Delete Button
            deleteButton.topAnchor.constraint(equalTo: brightnessContainerView.bottomAnchor, constant: 30),
            deleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            deleteButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Disclaimer
            disclaimerLabel.topAnchor.constraint(equalTo: deleteButton.bottomAnchor, constant: 30),
            disclaimerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            disclaimerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            disclaimerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }
    
    private func setupBrightnessControl() {
        brightnessSlider.addTarget(self, action: #selector(brightnessChanged), for: .valueChanged)
    }
    
    private func addPulseAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 2.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.02
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .greatestFiniteMagnitude
        barcodeImageView.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    // MARK: - Trait Change Handling
    
    private func setupTraitChangeObserving() {
        if #available(iOS 17.0, *) {
            traitRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (vc: BarcodeViewController, _: UITraitCollection) in
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
            
            if isDarkMode {
                view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
                titleLabel.textColor = .white
                instructionLabel.textColor = UIColor(white: 0.8, alpha: 1.0)
                brightnessLabel.textColor = .white
                brightnessDescriptionLabel.textColor = UIColor.white.withAlphaComponent(0.7)
                
                // IMPORTANT: Make the barcode number WHITE in dark mode
                barcodeNumberLabel.textColor = .white
                
                // Card backgrounds need to be darker in dark mode
                barcodeContainerView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                brightnessContainerView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                
                // Always keep barcode background white for scanning
                barcodeImageView.backgroundColor = .white
                
                // Update navigation bar
                navigationController?.navigationBar.tintColor = .white
                navigationController?.navigationBar.barStyle = .black
            } else {
                view.backgroundColor = .white
                titleLabel.textColor = .textPrimary
                instructionLabel.textColor = .textSecondary
                brightnessLabel.textColor = .textPrimary
                brightnessDescriptionLabel.textColor = UIColor.textSecondary.withAlphaComponent(0.8)
                barcodeNumberLabel.textColor = .black
                
                // Card backgrounds
                barcodeContainerView.backgroundColor = .white
                brightnessContainerView.backgroundColor = .white
                
                // Navigation bar
                navigationController?.navigationBar.tintColor = .textPrimary
                navigationController?.navigationBar.barStyle = .default
            }
        }
    }
    
    // MARK: - Barcode Display
    
    private func displayBarcode() {
        guard isViewLoaded && view.window != nil else {
            // View not in hierarchy yet, delay barcode display
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.displayBarcode()
            }
            return
        }
        
        guard let barcodeString = BarcodeManager.shared.getStoredBarcode() else {
            showAlert(title: "Error", message: "No barcode found. Please scan a barcode first.") { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
            return
        }
        
        // Format the numeric display immediately
        barcodeNumberLabel.text = formatEAN13(barcodeString)
        
        // Ensure text color is correct for current mode
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                barcodeNumberLabel.textColor = .white
            } else {
                barcodeNumberLabel.textColor = .black
            }
        } else {
            barcodeNumberLabel.textColor = .black
        }
        
        // Center the barcode image view precisely
        let containerWidth = barcodeContainerView.bounds.width
        let imageWidth = containerWidth * 0.8
        barcodeImageView.frame = CGRect(
            x: (containerWidth - imageWidth) / 2,
            y: 30,
            width: imageWidth,
            height: 140
        )
        
        // Generate barcode on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Generate barcode image
            let barcodeImage = self.generateBarcodeFromString(barcodeString)
            
            DispatchQueue.main.async {
                if let image = barcodeImage {
                    // Apply a subtle fade animation
                    self.barcodeImageView.alpha = 0
                    self.barcodeImageView.image = image
                    
                    UIView.animate(withDuration: 0.5) {
                        self.barcodeImageView.alpha = 1
                    }
                } else {
                    self.showAlert(title: "Error", message: "Could not generate barcode image.") { [weak self] _ in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    private func formatEAN13(_ code: String) -> String {
        guard code.count == 13 else { return code }
        
        // Format as: X-XXXXXX-XXXXX-X
        let index1 = code.index(code.startIndex, offsetBy: 1)
        let index7 = code.index(code.startIndex, offsetBy: 7)
        let index12 = code.index(code.startIndex, offsetBy: 12)
        
        let part1 = code[..<index1]
        let part2 = code[index1..<index7]
        let part3 = code[index7..<index12]
        let part4 = code[index12...]
        
        return "\(part1)-\(part2)-\(part3)-\(part4)"
    }
    
    // MARK: - Barcode Generation
    
    private func generateBarcodeFromString(_ string: String) -> UIImage? {
        guard string.count == 13, string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            return nil
        }
        
        // Convert string to array of integers
        let digits = string.compactMap { Int(String($0)) }
        
        // Define the patterns for EAN-13
        let leftOddPatterns = [
            "0001101", "0011001", "0010011", "0111101", "0100011",
            "0110001", "0101111", "0111011", "0110111", "0001011"
        ]
        
        let leftEvenPatterns = [
            "0100111", "0110011", "0011011", "0100001", "0011101",
            "0111001", "0000101", "0010001", "0001001", "0010111"
        ]
        
        let rightPatterns = [
            "1110010", "1100110", "1101100", "1000010", "1011100",
            "1001110", "1010000", "1000100", "1001000", "1110100"
        ]
        
        // First digit determines the pattern of the left side
        let firstDigitPatterns = [
            [0, 0, 0, 0, 0, 0], // 0 = all odd parity on left side
            [0, 0, 1, 0, 1, 1], // 1
            [0, 0, 1, 1, 0, 1], // 2
            [0, 0, 1, 1, 1, 0], // 3
            [0, 1, 0, 0, 1, 1], // 4
            [0, 1, 1, 0, 0, 1], // 5
            [0, 1, 1, 1, 0, 0], // 6
            [0, 1, 0, 1, 0, 1], // 7
            [0, 1, 0, 1, 1, 0], // 8
            [0, 1, 1, 0, 1, 0]  // 9
        ]
        
        // Start building the barcode pattern
        var barcodePattern = ""
        
        // Left quiet zone (should be at least 11 modules wide for EAN-13)
        barcodePattern += "00000000000"
        
        // Start guard pattern (special marker)
        barcodePattern += "101"
        
        // Left side (digits 1-6) - encoded based on first digit
        let firstDigit = digits[0]
        let parityPattern = firstDigitPatterns[firstDigit]
        
        for i in 1...6 {
            let digit = digits[i]
            if parityPattern[i-1] == 0 {
                barcodePattern += leftOddPatterns[digit]  // Odd parity
            } else {
                barcodePattern += leftEvenPatterns[digit] // Even parity
            }
        }
        
        // Middle guard pattern (special marker)
        barcodePattern += "01010"
        
        // Right side (digits 7-12) - always right pattern
        for i in 7...12 {
            let digit = digits[i]
            barcodePattern += rightPatterns[digit]
        }
        
        // End guard pattern (special marker)
        barcodePattern += "101"
        
        // Right quiet zone (should be at least 7 modules wide for EAN-13)
        barcodePattern += "0000000"
        
        // Draw the barcode with enhanced features
        let moduleWidth: CGFloat = 3.0 // Width of narrowest bar
        let height: CGFloat = 140.0 // Height without the text area
        
        // Calculate width based on pattern length and module width
        let width = CGFloat(barcodePattern.count) * moduleWidth
        
        // Create a graphics context - no extra space for text
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, UIScreen.main.scale)
        
        // Fill with white background
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Draw black bars
        UIColor.black.setFill()
        
        var xPosition: CGFloat = 0
        for (index, character) in barcodePattern.enumerated() {
            if character == "1" {
                // Determine if this is part of the guard patterns
                var barHeight = height - 20 // Standard bar height
                
                // Define guard bar indices
                let startGuardIndices = [11, 12, 13]
                let middleGuardIndices = [11+7*6+3, 11+7*6+4, 11+7*6+5, 11+7*6+6, 11+7*6+7]
                let endGuardIndices = [11+7*6+5*7+3, 11+7*6+5*7+4, 11+7*6+5*7+5]
                
                if startGuardIndices.contains(index) || middleGuardIndices.contains(index) || endGuardIndices.contains(index) {
                    barHeight = height // Full height for guard patterns
                }
                
                let barRect = CGRect(x: xPosition, y: 0, width: moduleWidth, height: barHeight)
                UIRectFill(barRect)
            }
            xPosition += moduleWidth
        }
        
        // Get the final image - NO TEXT RENDERING
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "Delete Barcode",
            message: "Are you sure you want to delete this barcode? You'll need to scan it again to use it.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            // Delete the barcode
            BarcodeManager.shared.deleteStoredBarcode()
            
            // Show confirmation
            let confirmationAlert = UIAlertController(
                title: "Barcode Deleted",
                message: "Your barcode has been removed.",
                preferredStyle: .alert
            )
            confirmationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }))
            self?.present(confirmationAlert, animated: true)
        }))
        
        present(alert, animated: true)
    }
    
    @objc private func brightnessChanged(_ sender: UISlider) {
        UIScreen.main.brightness = CGFloat(sender.value)
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        present(alert, animated: true)
    }
}
