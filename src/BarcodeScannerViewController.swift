import UIKit
import AVFoundation

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var traitRegistration: NSObjectProtocol?
    
    // Target red color that works in both light and dark mode
    private var targetRedColor: UIColor {
        return UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    }
    
    // MARK: - UI Elements
    
    private let scannerOverlayView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 3
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var scannerCorners: [UIView] = {
        let cornerLength: CGFloat = 20
        let cornerWidth: CGFloat = 5
        var corners = [UIView]()
        
        // Create 8 corner elements (4 corners x 2 lines each)
        for _ in 0..<8 {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            corners.append(view)
        }
        
        return corners
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Position the EAN-13 barcode within the frame"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scanningAnimation: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scan Barcode"
        view.backgroundColor = .black
        setupUI()
        setupCaptureSession()
        updateColorsForCurrentMode()
        setupTraitChangeObserving()
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update preview layer frame
        previewLayer?.frame = view.layer.bounds
        
        // Update scanner corners
        setupCorners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            // Start capture session on a background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
        
        // Start scanning animation
        startScanningAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            // Stop capture session on a background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
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
            traitRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (vc: BarcodeScannerViewController, _: UITraitCollection) in
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
        view.addSubview(scannerOverlayView)
        for corner in scannerCorners {
            scannerOverlayView.addSubview(corner)
        }
        view.addSubview(instructionLabel)
        view.addSubview(scanningAnimation)
        view.addSubview(cancelButton)
        
        // Sizing the scanner overlay to be appropriate for barcode scanning
        NSLayoutConstraint.activate([
            scannerOverlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scannerOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scannerOverlayView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            scannerOverlayView.heightAnchor.constraint(equalTo: scannerOverlayView.widthAnchor, multiplier: 0.4), // Good aspect ratio for barcode
            
            instructionLabel.bottomAnchor.constraint(equalTo: scannerOverlayView.topAnchor, constant: -24),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionLabel.heightAnchor.constraint(equalToConstant: 44),
            
            scanningAnimation.leadingAnchor.constraint(equalTo: scannerOverlayView.leadingAnchor),
            scanningAnimation.trailingAnchor.constraint(equalTo: scannerOverlayView.trailingAnchor),
            scanningAnimation.heightAnchor.constraint(equalToConstant: 2),
            scanningAnimation.topAnchor.constraint(equalTo: scannerOverlayView.topAnchor),
            
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            cancelButton.widthAnchor.constraint(equalToConstant: 160),
            cancelButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add button actions
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }
    
    private func setupCorners() {
        let width = scannerOverlayView.bounds.width
        let height = scannerOverlayView.bounds.height
        let cornerLength: CGFloat = 20
        let cornerWidth: CGFloat = 5
        
        // Top-left horizontal
        scannerCorners[0].frame = CGRect(x: 0, y: 0, width: cornerLength, height: cornerWidth)
        
        // Top-left vertical
        scannerCorners[1].frame = CGRect(x: 0, y: 0, width: cornerWidth, height: cornerLength)
        
        // Top-right horizontal
        scannerCorners[2].frame = CGRect(x: width - cornerLength, y: 0, width: cornerLength, height: cornerWidth)
        
        // Top-right vertical
        scannerCorners[3].frame = CGRect(x: width - cornerWidth, y: 0, width: cornerWidth, height: cornerLength)
        
        // Bottom-left horizontal
        scannerCorners[4].frame = CGRect(x: 0, y: height - cornerWidth, width: cornerLength, height: cornerWidth)
        
        // Bottom-left vertical
        scannerCorners[5].frame = CGRect(x: 0, y: height - cornerLength, width: cornerWidth, height: cornerLength)
        
        // Bottom-right horizontal
        scannerCorners[6].frame = CGRect(x: width - cornerLength, y: height - cornerWidth, width: cornerLength, height: cornerWidth)
        
        // Bottom-right vertical
        scannerCorners[7].frame = CGRect(x: width - cornerWidth, y: height - cornerLength, width: cornerWidth, height: cornerLength)
    }
    
    private func updateColorsForCurrentMode() {
        // Always use target red for important UI elements
        scannerOverlayView.layer.borderColor = targetRedColor.cgColor
        instructionLabel.backgroundColor = targetRedColor.withAlphaComponent(0.8)
        scanningAnimation.backgroundColor = targetRedColor.withAlphaComponent(0.5)
        
        // Set corner colors
        for corner in scannerCorners {
            corner.backgroundColor = targetRedColor
        }
        
        if #available(iOS 13.0, *) {
            // Adapt button colors for dark mode
            cancelButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
            cancelButton.setTitleColor(targetRedColor, for: .normal)
        } else {
            // Fallback for iOS 12
            cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            cancelButton.setTitleColor(targetRedColor, for: .normal)
        }
    }
    
    private func startScanningAnimation() {
        // Reset the animation position
        self.scanningAnimation.transform = .identity
        
        // Animate scanning line
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut, .repeat, .autoreverse], animations: {
            self.scanningAnimation.transform = CGAffineTransform(translationX: 0, y: self.scannerOverlayView.bounds.height - 2)
        })
    }
    
    // MARK: - Camera Setup
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showAlert(title: "Error", message: "Could not access the camera. Please check your permissions.")
            return
        }
        
        if (captureSession?.canAddInput(videoInput) ?? false) {
            captureSession?.addInput(videoInput)
        } else {
            showAlert(title: "Error", message: "Your device does not support scanning barcodes.")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession?.canAddOutput(metadataOutput) ?? false) {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13] // Focus on EAN-13 barcodes
            
            // Set the scan area to match our overlay
            DispatchQueue.main.async {
                guard let previewLayer = self.previewLayer else { return }
                
                // Convert scannerOverlayView frame to metadataOutput's coordinate space
                let rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: self.scannerOverlayView.frame)
                metadataOutput.rectOfInterest = rectOfInterest
            }
        } else {
            showAlert(title: "Error", message: "Your device does not support scanning barcodes.")
            return
        }
        
        // Configure preview layer
        if let captureSession = self.captureSession {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = view.layer.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            if let previewLayer = previewLayer {
                view.layer.insertSublayer(previewLayer, at: 0)
                
                // Make sure our overlay views are on top of the preview layer
                view.bringSubviewToFront(scannerOverlayView)
                view.bringSubviewToFront(instructionLabel)
                view.bringSubviewToFront(scanningAnimation)
                view.bringSubviewToFront(cancelButton)
            }
        }
        
        // Start capturing on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Stop capturing as soon as we get a result
        captureSession?.stopRunning()
        
        // Add haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        
        // Process the captured barcode
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Vibrate when barcode detected
            feedbackGenerator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // Check that it's an EAN-13 barcode (should be 13 digits)
            if stringValue.count == 13 && stringValue.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
                // Save the barcode
                let manager = BarcodeManager.shared
                manager.saveBarcode(stringValue)
                
                // Show success animation
                UIView.animate(withDuration: 0.3, animations: {
                    self.scannerOverlayView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    self.scannerOverlayView.layer.borderColor = UIColor.green.cgColor
                }, completion: { _ in
                    UIView.animate(withDuration: 0.2, animations: {
                        self.scannerOverlayView.transform = .identity
                    }, completion: { _ in
                        // Show success and navigate back
                        self.showSuccessAlert(barcode: stringValue)
                    })
                })
            } else {
                feedbackGenerator.notificationOccurred(.error)
                showAlert(title: "Invalid Barcode", message: "Please scan a valid EAN-13 barcode.") { [weak self] _ in
                    self?.captureSession?.startRunning()
                    self?.startScanningAnimation()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helper Methods
    
    private func showSuccessAlert(barcode: String) {
        let alert = UIAlertController(
            title: "Barcode Captured!",
            message: "Successfully saved barcode: \(formatBarcode(barcode))",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "View Barcode", style: .default, handler: { [weak self] _ in
            let barcodeVC = BarcodeViewController()
            self?.navigationController?.pushViewController(barcodeVC, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        
        present(alert, animated: true)
    }
    
    private func formatBarcode(_ code: String) -> String {
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
    
    private func showAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        present(alert, animated: true)
    }
}
