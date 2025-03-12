import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    private var traitRegistration: NSObjectProtocol?
    
    // Target red color that works in both light and dark mode
    private var targetRedColor: UIColor {
        return UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    }
    
    // MARK: - UI Elements
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "barcode.viewfinder")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scan Barcode", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let viewBarcodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View Saved Barcode", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Target Team Member Card"
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Scan and store your Target team member discount barcode"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let cardContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateColorsForCurrentMode()
        setupTraitChangeObserving()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateButtonStates()
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
            traitRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (vc: HomeViewController, _: UITraitCollection) in
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
        view.addSubview(cardContainer)
        cardContainer.addSubview(logoImageView)
        cardContainer.addSubview(titleLabel)
        cardContainer.addSubview(descriptionLabel)
        view.addSubview(scanButton)
        view.addSubview(viewBarcodeButton)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            cardContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            cardContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            
            logoImageView.centerXAnchor.constraint(equalTo: cardContainer.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 30),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -30),
            
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.topAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: 40),
            scanButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            scanButton.heightAnchor.constraint(equalToConstant: 56),
            
            viewBarcodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            viewBarcodeButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 20),
            viewBarcodeButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            viewBarcodeButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Add button actions
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        viewBarcodeButton.addTarget(self, action: #selector(viewBarcodeButtonTapped), for: .touchUpInside)
        
        // Set navigation bar title and appearance
        title = "Target Card Scanner"
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        // Add subtle animation
        logoImageView.alpha = 0
        titleLabel.alpha = 0
        descriptionLabel.alpha = 0
        
        UIView.animate(withDuration: 0.8, delay: 0.2, options: .curveEaseOut) {
            self.logoImageView.alpha = 1
            self.titleLabel.alpha = 1
            self.descriptionLabel.alpha = 1
        }
    }
    
    private func updateColorsForCurrentMode() {
        // Dynamic colors based on light/dark mode
        if #available(iOS 13.0, *) {
            // Background colors
            view.backgroundColor = UIColor.systemBackground
            cardContainer.backgroundColor = UIColor.secondarySystemBackground
            cardContainer.layer.shadowColor = UIColor.label.cgColor
            
            // Text colors
            titleLabel.textColor = targetRedColor
            descriptionLabel.textColor = UIColor.secondaryLabel
            
            // Button colors
            scanButton.backgroundColor = targetRedColor
            viewBarcodeButton.backgroundColor = targetRedColor
            
            // Navigation bar appearance
            navigationController?.navigationBar.tintColor = targetRedColor
            
            // Logo color
            logoImageView.tintColor = targetRedColor
        } else {
            // Fallback for iOS 12 and below
            view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
            cardContainer.backgroundColor = .white
            titleLabel.textColor = targetRedColor
            descriptionLabel.textColor = .darkGray
            scanButton.backgroundColor = targetRedColor
            viewBarcodeButton.backgroundColor = targetRedColor
            navigationController?.navigationBar.tintColor = targetRedColor
            logoImageView.tintColor = targetRedColor
        }
    }
    
    // MARK: - Actions
    
    @objc private func scanButtonTapped() {
        let scannerVC = BarcodeScannerViewController()
        navigationController?.pushViewController(scannerVC, animated: true)
    }
    
    @objc private func viewBarcodeButtonTapped() {
        let barcodeVC = BarcodeViewController()
        navigationController?.pushViewController(barcodeVC, animated: true)
    }
    
    private func updateButtonStates() {
        // Check if we have a stored barcode
        let hasSavedBarcode = BarcodeManager.shared.hasStoredBarcode()
        
        // Update the button appearance
        if hasSavedBarcode {
            viewBarcodeButton.alpha = 1.0
            viewBarcodeButton.isEnabled = true
        } else {
            viewBarcodeButton.alpha = 0.5
            viewBarcodeButton.isEnabled = false
        }
    }
}
