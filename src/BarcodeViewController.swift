import UIKit
import CoreImage

class BarcodeViewController: UIViewController {
    
    // MARK: - Properties
    
    private var brightnessBeforeShow: CGFloat = 0
    private var traitRegistration: NSObjectProtocol?
    
    // Target red color that works in both light and dark mode
    private var targetRedColor: UIColor {
        return UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    }
    
    // MARK: - UI Elements
    
    private let cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let barcodeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let barcodeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Present this barcode at checkout"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let targetLogoView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "target")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let teamMemberLabel: UILabel = {
        let label = UILabel()
        label.text = "TEAM MEMBER DISCOUNT"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Barcode", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemRed
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let brightnessSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = Float(UIScreen.main.brightness)
        slider.minimumValueImage = UIImage(systemName: "sun.min")
        slider.maximumValueImage = UIImage(systemName: "sun.max")
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Team Member Card"
        
        // Fix for title truncation
        if let navigationBar = navigationController?.navigationBar {
            // Adjust title text attributes to use a slightly smaller font
            navigationBar.titleTextAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold)
            ]
        }
        
        setupUI()
        setupBrightnessControl()
        updateColorsForCurrentMode()
        setupTraitChangeObserving()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Store current brightness
        brightnessBeforeShow = UIScreen.main.brightness
        
        // Auto-increase brightness for better scanning
        UIScreen.main.brightness = 0.8
        brightnessSlider.value = Float(UIScreen.main.brightness)
        
        // Wait until view is fully in hierarchy before attempting to display barcode
        displayBarcode()
        
        // Add a subtle pulse animation to the card
        addPulseAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Restore original brightness
        UIScreen.main.brightness = brightnessBeforeShow
    }
    
    deinit {
        // Remove the trait change registration if it exists
        if let registration = traitRegistration {
            NotificationCenter.default.removeObserver(registration)
        }
    }
    
    // MARK: - Trait Change Handling
    
    private func setupTraitChangeObserving() {
        if #available(iOS 17.0, *) {
            // Use the new API for iOS 17+ with proper type annotations
            traitRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (vc: BarcodeViewController, _: UITraitCollection) in
                guard let self = self else { return }
                self.updateColorsForCurrentMode()
            }
        }
        // For iOS versions < 17, traitCollectionDidChange will be used
    }
    
    // Support for iOS versions before 17.0
    @available(iOS, deprecated: 17.0, message: "Use the trait change registration APIs")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 17.0, *) {
            // Using the registration API for iOS 17+
        } else {
            // For older iOS versions, use the traditional approach
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateColorsForCurrentMode()
            }
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Add subviews
        view.addSubview(cardView)
        cardView.addSubview(targetLogoView)
        cardView.addSubview(teamMemberLabel)
        cardView.addSubview(barcodeImageView)
        cardView.addSubview(instructionLabel)
        // We're removing the barcodeLabel since it's redundant with the text in the barcode image
        view.addSubview(brightnessSlider)
        view.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: brightnessSlider.topAnchor, constant: -20),
            
            targetLogoView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            targetLogoView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            targetLogoView.widthAnchor.constraint(equalToConstant: 40),
            targetLogoView.heightAnchor.constraint(equalToConstant: 40),
            
            teamMemberLabel.topAnchor.constraint(equalTo: targetLogoView.bottomAnchor, constant: 8),
            teamMemberLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            teamMemberLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            teamMemberLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            instructionLabel.topAnchor.constraint(equalTo: teamMemberLabel.bottomAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            barcodeImageView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 20),
            barcodeImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            barcodeImageView.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.9),
            barcodeImageView.heightAnchor.constraint(equalTo: cardView.heightAnchor, multiplier: 0.5),
            barcodeImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            
            brightnessSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            brightnessSlider.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            brightnessSlider.bottomAnchor.constraint(equalTo: deleteButton.topAnchor, constant: -30),
            
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            deleteButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            deleteButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add button actions
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    private func updateColorsForCurrentMode() {
        // Dynamic background colors
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
            cardView.backgroundColor = UIColor.secondarySystemBackground
            cardView.layer.shadowColor = UIColor.label.cgColor.copy(alpha: 0.2)
            barcodeImageView.backgroundColor = .white // Always white for barcodes
            
            // Target red is consistent across modes
            targetLogoView.tintColor = targetRedColor
            teamMemberLabel.textColor = targetRedColor
            instructionLabel.textColor = targetRedColor
            brightnessSlider.tintColor = targetRedColor
            
            // Text colors adapt to mode
            barcodeLabel.textColor = UIColor.label
            
            // Icons adapt to mode
            brightnessSlider.minimumValueImage = UIImage(systemName: "sun.min")?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
            brightnessSlider.maximumValueImage = UIImage(systemName: "sun.max")?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
        } else {
            // Fallback for iOS 12 and below
            view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
            cardView.backgroundColor = .white
            targetLogoView.tintColor = targetRedColor
            teamMemberLabel.textColor = targetRedColor
            instructionLabel.textColor = targetRedColor
            barcodeLabel.textColor = .darkGray
            brightnessSlider.tintColor = targetRedColor
        }
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
    
    // MARK: - Barcode Generation
    
    private func displayBarcode() {
        guard isViewLoaded && view.window != nil else {
            print("View not in hierarchy yet, delaying barcode display")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.displayBarcode()
            }
            return
        }
        
        guard let barcodeString = BarcodeManager.shared.getStoredBarcode() else {
            navigateBackWithError(title: "Error", message: "No barcode found. Please scan a barcode first.")
            return
        }
        
        // Generate barcode image
        if let barcodeImage = generateBarcodeFromString(barcodeString) {
            barcodeImageView.image = barcodeImage
            
            // Add a subtle animation when the barcode appears
            barcodeImageView.alpha = 0
            UIView.animate(withDuration: 0.5) {
                self.barcodeImageView.alpha = 1
            }
        } else {
            navigateBackWithError(title: "Error", message: "Could not generate barcode image.")
        }
    }
    
    private func formatEAN13(_ code: String) -> String {
        guard code.count == 13 else { return code }
        
        // EAN-13 format: first digit, group of 6 digits, group of 5 digits, check digit
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
    
    private func generateBarcodeFromString(_ string: String) -> UIImage? {
        print("Generating strictly EAN-13 barcode for: \(string)")
        
        // Make sure it's a valid EAN-13 barcode number
        guard string.count == 13,
              string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            print("Invalid EAN-13 format: must be exactly 13 digits")
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
        
        // Start guard pattern
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
        
        // Middle guard pattern
        barcodePattern += "01010"
        
        // Right side (digits 7-12) - always right pattern
        for i in 7...12 {
            let digit = digits[i]
            barcodePattern += rightPatterns[digit]
        }
        
        // End guard pattern
        barcodePattern += "101"
        
        // Right quiet zone (should be at least 7 modules wide for EAN-13)
        barcodePattern += "0000000"
        
        // Draw the barcode - each module is 1 unit wide (we'll scale later)
        let moduleWidth: CGFloat = 3.0 // Width of narrowest bar, adjust for better scanning
        let height: CGFloat = 120.0
        
        // Calculate width based on pattern length and module width
        let width = CGFloat(barcodePattern.count) * moduleWidth
        
        // Create a graphics context
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height+30), false, UIScreen.main.scale)
        
        // Fill with white background
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: width, height: height+30))
        
        // Draw black bars
        UIColor.black.setFill()
        
        var xPosition: CGFloat = 0
        for character in barcodePattern {
            if character == "1" {
                let barRect = CGRect(x: xPosition, y: 0, width: moduleWidth, height: height)
                UIRectFill(barRect)
            }
            xPosition += moduleWidth
        }
        
        // Draw the formatted barcode number below the barcode
        let formattedString = formatEAN13(string)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let textRect = CGRect(x: 0, y: height + 5, width: width, height: 25)
        formattedString.draw(in: textRect, withAttributes: textAttributes)
        
        // Get the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        print("Successfully generated EAN-13 barcode")
        return finalImage
    }
    
    // MARK: - Actions
    
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
    
    private func navigateBackWithError(title: String, message: String) {
        guard isViewLoaded && view.window != nil else {
            print("Cannot show alert, view not in hierarchy")
            DispatchQueue.main.async { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true)
    }
}
