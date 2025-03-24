import UIKit
import AVFoundation

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - UI Elements
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Position EAN-13 barcode in frame"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scannerOverlayView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        view.backgroundColor = .clear
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var scannerCorners: [UIView] = {
        var corners = [UIView]()
        
        // Create 4 corner pieces
        for _ in 0..<4 {
            let view = UIView()
            view.backgroundColor = .clear
            view.translatesAutoresizingMaskIntoConstraints = false
            corners.append(view)
        }
        
        return corners
    }()
    
    private let scanningLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let successOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.alpha = 0
        view.isUserInteractionEnabled = true // Ensure this is true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let successCard: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.isUserInteractionEnabled = true // Ensure this is true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let successIcon: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            imageView.image = UIImage(systemName: "checkmark.circle.fill")
            imageView.tintColor = UIColor.brandGradientStart
        }
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let successTitle: UILabel = {
        let label = UILabel()
        label.text = "Barcode Captured"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let successNumber: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let viewBarcodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View Barcode", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 25
        button.isUserInteractionEnabled = true // Ensure this is true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.setTitleColor(.textSecondary, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.isUserInteractionEnabled = true // Ensure this is true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var scanningLineTopConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCaptureSession()
        
        // Listen for barcode deletion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetCaptureSession),
            name: NSNotification.Name("BarcodeDeleted"),
            object: nil
        )
        
        print("VC loaded, UI setup complete")
    }
    
    @objc private func resetCaptureSession() {
        // Ensure we completely reset the capture session
        captureSession?.stopRunning()
        
        // Clear existing session
        captureSession = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        
        // Re-setup capture session
        setupCaptureSession()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Reset success overlay
        successOverlay.alpha = 0
        
        // Start capture session safely
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let session = self.captureSession, !session.isRunning else { return }
            self.captureSession?.startRunning()
        }
        
        // Start scanning animation
        startScanningAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Restore navigation bar
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // Stop animations
        scanningLine.layer.removeAllAnimations()
        
        // Stop session
        captureSession?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update preview layer frame
        previewLayer?.frame = view.layer.bounds
        
        // Update scanning line frame
        scanningLine.frame.size.width = scannerOverlayView.frame.width
        
        // Update scanner corners
        updateCornerPositions()
        
        // Make sure gradient is applied to view barcode button
        if viewBarcodeButton.layer.sublayers?.contains(where: { $0 is CAGradientLayer }) != true {
            viewBarcodeButton.applyBrandGradient()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Background
        view.backgroundColor = .black
        
        // Configure UI elements
        scanningLine.applyBrandGradient()
        
        // Add corner views
        for i in 0..<scannerCorners.count {
            let cornerPath = UIBezierPath()
            let shapeLayer = CAShapeLayer()
            
            switch i {
            case 0: // Top Left
                cornerPath.move(to: CGPoint(x: 0, y: 0))
                cornerPath.addLine(to: CGPoint(x: 20, y: 0))
                cornerPath.move(to: CGPoint(x: 0, y: 0))
                cornerPath.addLine(to: CGPoint(x: 0, y: 20))
            case 1: // Top Right
                cornerPath.move(to: CGPoint(x: 0, y: 0))
                cornerPath.addLine(to: CGPoint(x: -20, y: 0))
                cornerPath.move(to: CGPoint(x: 0, y: 0))
                cornerPath.addLine(to: CGPoint(x: 0, y: 20))
            case 2: // Bottom Left
                cornerPath.move(to: CGPoint(x: 0, y: 0))
                cornerPath.addLine(to: CGPoint(x: 20, y: 0))
                cornerPath.move(to: CGPoint(x: 0, y: 0))
                cornerPath.addLine(to: CGPoint(x: 0, y: -20))
            case 3: // Bottom Right
                cornerPath.move(to: CGPoint(x: 0, y: 0))
                cornerPath.addLine(to: CGPoint(x: -20, y: 0))
                cornerPath.move(to: CGPoint(x: 0, y: 0))
                cornerPath.addLine(to: CGPoint(x: 0, y: -20))
            default:
                break
            }
            
            shapeLayer.path = cornerPath.cgPath
            shapeLayer.strokeColor = UIColor.brandGradientStart.cgColor
            shapeLayer.lineWidth = 3
            shapeLayer.lineCap = .round
            
            scannerCorners[i].layer.addSublayer(shapeLayer)
        }
        
        // Configure buttons with clear styling
        viewBarcodeButton.applyBrandGradient()
        
        // Add subviews
        view.addSubview(instructionLabel)
        view.addSubview(scannerOverlayView)
        for corner in scannerCorners {
            view.addSubview(corner)
        }
        view.addSubview(scanningLine)
        view.addSubview(cancelButton)
        
        // Success overlay - add after main view to ensure it's on top
        view.addSubview(successOverlay)
        successOverlay.addSubview(successCard)
        successCard.addSubview(successIcon)
        successCard.addSubview(successTitle)
        successCard.addSubview(successNumber)
        successCard.addSubview(viewBarcodeButton)
        successCard.addSubview(doneButton)
        
        // Set up constraints
        scanningLineTopConstraint = scanningLine.topAnchor.constraint(equalTo: scannerOverlayView.topAnchor)
        
        NSLayoutConstraint.activate([
            // Instruction
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Scanner Overlay
            scannerOverlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scannerOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scannerOverlayView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            scannerOverlayView.heightAnchor.constraint(equalTo: scannerOverlayView.widthAnchor, multiplier: 0.5),
            
            // Scanner Line
            scanningLine.leadingAnchor.constraint(equalTo: scannerOverlayView.leadingAnchor),
            scanningLine.widthAnchor.constraint(equalTo: scannerOverlayView.widthAnchor),
            scanningLine.heightAnchor.constraint(equalToConstant: 1),
            scanningLineTopConstraint!,
            
            // Cancel Button
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Success Overlay
            successOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            successOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            successOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            successOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Success Card
            successCard.centerXAnchor.constraint(equalTo: successOverlay.centerXAnchor),
            successCard.centerYAnchor.constraint(equalTo: successOverlay.centerYAnchor),
            successCard.widthAnchor.constraint(equalToConstant: 250),
            successCard.heightAnchor.constraint(equalToConstant: 250),
            
            // Success Icon
            successIcon.topAnchor.constraint(equalTo: successCard.topAnchor, constant: 30),
            successIcon.centerXAnchor.constraint(equalTo: successCard.centerXAnchor),
            successIcon.widthAnchor.constraint(equalToConstant: 60),
            successIcon.heightAnchor.constraint(equalToConstant: 60),
            
            // Success Title
            successTitle.topAnchor.constraint(equalTo: successIcon.bottomAnchor, constant: 16),
            successTitle.leadingAnchor.constraint(equalTo: successCard.leadingAnchor, constant: 16),
            successTitle.trailingAnchor.constraint(equalTo: successCard.trailingAnchor, constant: -16),
            
            // Success Number
            successNumber.topAnchor.constraint(equalTo: successTitle.bottomAnchor, constant: 8),
            successNumber.leadingAnchor.constraint(equalTo: successCard.leadingAnchor, constant: 16),
            successNumber.trailingAnchor.constraint(equalTo: successCard.trailingAnchor, constant: -16),
            
            // View Barcode Button
            viewBarcodeButton.topAnchor.constraint(equalTo: successNumber.bottomAnchor, constant: 24),
            viewBarcodeButton.centerXAnchor.constraint(equalTo: successCard.centerXAnchor),
            viewBarcodeButton.widthAnchor.constraint(equalToConstant: 180),
            viewBarcodeButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Done Button
            doneButton.topAnchor.constraint(equalTo: viewBarcodeButton.bottomAnchor, constant: 12),
            doneButton.centerXAnchor.constraint(equalTo: successCard.centerXAnchor)
        ])
        
        // Add actions with strong references
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        viewBarcodeButton.addTarget(self, action: #selector(viewBarcodeButtonTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        // Add debug tap gestures to confirm overlay interactivity
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewBarcodeButtonTapped))
        viewBarcodeButton.addGestureRecognizer(tapGesture)
        
        let doneTapGesture = UITapGestureRecognizer(target: self, action: #selector(doneButtonTapped))
        doneButton.addGestureRecognizer(doneTapGesture)
    }
    
    private func updateCornerPositions() {
        let positions: [(CGPoint, CGPoint)] = [
            (.zero, scannerOverlayView.frame.origin), // Top Left
            (CGPoint(x: scannerOverlayView.frame.width, y: 0),
             CGPoint(x: scannerOverlayView.frame.maxX, y: scannerOverlayView.frame.minY)), // Top Right
            (CGPoint(x: 0, y: scannerOverlayView.frame.height),
             CGPoint(x: scannerOverlayView.frame.minX, y: scannerOverlayView.frame.maxY)), // Bottom Left
            (CGPoint(x: scannerOverlayView.frame.width, y: scannerOverlayView.frame.height),
             CGPoint(x: scannerOverlayView.frame.maxX, y: scannerOverlayView.frame.maxY)) // Bottom Right
        ]
        
        for (i, (_, viewPoint)) in positions.enumerated() {
            scannerCorners[i].frame = CGRect(x: viewPoint.x - 3, y: viewPoint.y - 3, width: 6, height: 6)
        }
    }
    
    private func startScanningAnimation() {
        // Reset position
        scanningLineTopConstraint?.constant = 0
        view.layoutIfNeeded()
        
        // Stop any existing animations
        scanningLine.layer.removeAllAnimations()
        
        // Animate the scanning line
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut, .repeat, .autoreverse], animations: {
            self.scanningLineTopConstraint?.constant = self.scannerOverlayView.frame.height - 1
            self.view.layoutIfNeeded()
        })
    }
    
    // MARK: - Camera Setup
    
    private func setupCaptureSession() {
        // First check if we already have a running session
        if captureSession?.isRunning == true {
            return
        }
        
        // Initialize capture session
        captureSession = AVCaptureSession()
        
        // Get video capture device
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showAlert(title: "Error", message: "Camera not available on this device")
            return
        }
        
        // Create input with better error handling
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "Camera Access Error",
                               message: "Could not access the camera: \(error.localizedDescription)")
            }
            return
        }
        
        // Add input to session
        if captureSession?.canAddInput(videoInput) ?? false {
            captureSession?.addInput(videoInput)
        } else {
            showAlert(title: "Error", message: "Could not add video input")
            return
        }
        
        // Create metadata output
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession?.canAddOutput(metadataOutput) ?? false {
            captureSession?.addOutput(metadataOutput)
            
            // Set delegate
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13]
            
            // Set scan rect
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let previewLayer = self.previewLayer {
                    let rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: self.scannerOverlayView.frame)
                    metadataOutput.rectOfInterest = rectOfInterest
                }
            }
        } else {
            showAlert(title: "Error", message: "Could not add metadata output")
            return
        }
        
        // Create preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.layer.bounds
        view.layer.insertSublayer(previewLayer!, at: 0)
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if we have at least one object
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue,
           metadataObject.type == .ean13 {
            
            // Stop capturing
            captureSession?.stopRunning()
            
            // Stop scanning animation
            scanningLine.layer.removeAllAnimations()
            
            // Give haptic feedback
            if #available(iOS 10.0, *) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            AudioServicesPlaySystemSound(1520) // Vibrate
            
            // Validate it's a proper EAN-13 code
            if stringValue.count == 13 && stringValue.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
                // Save the code
                BarcodeManager.shared.saveBarcode(stringValue)
                
                // Show success animation
                showSuccess(barcode: stringValue)
            } else {
                // Invalid format
                showAlert(title: "Invalid Barcode", message: "The scanned barcode is not a valid EAN-13 format.") { [weak self] _ in
                    // Restart scanning
                    DispatchQueue.global(qos: .userInitiated).async {
                        self?.captureSession?.startRunning()
                    }
                    self?.startScanningAnimation()
                }
            }
        }
    }
    
    // MARK: - Actions & Animations
    
    private func showSuccess(barcode: String) {
        // Format barcode
        successNumber.text = formatEAN13(barcode)
        
        // Reset view state
        successOverlay.alpha = 0
        successCard.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Ensure buttons are on top and interactive
        successCard.bringSubviewToFront(viewBarcodeButton)
        successCard.bringSubviewToFront(doneButton)
        viewBarcodeButton.isUserInteractionEnabled = true
        doneButton.isUserInteractionEnabled = true
        
        // Animate success card
        UIView.animate(withDuration: 0.3) {
            self.successOverlay.alpha = 1
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.successCard.transform = .identity
        })
        
        // IMPORTANT: Add automatic navigation after delay as a failsafe
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            // Check if we're still on this screen after 5 seconds
            if self?.successOverlay.alpha == 1 {
                print("Auto-navigating after timeout")
                self?.successOverlay.alpha = 0
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        // Debug printing to check state
        print("Success overlay shown")
        print("viewBarcodeButton interactive: \(viewBarcodeButton.isUserInteractionEnabled)")
        print("doneButton interactive: \(doneButton.isUserInteractionEnabled)")
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
    
    @objc private func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func viewBarcodeButtonTapped() {
        print("View barcode button tapped")
        
        // Immediately disable further interaction to prevent double-taps
        viewBarcodeButton.isUserInteractionEnabled = false
        doneButton.isUserInteractionEnabled = false
        
        // Immediately hide overlay
        successOverlay.alpha = 0
        
        // Clean up resources
        captureSession?.stopRunning()
        scanningLine.layer.removeAllAnimations()
        
        // Navigate directly, no animation delay
        let barcodeVC = BarcodeViewController()
        navigationController?.pushViewController(barcodeVC, animated: true)
    }

    @objc private func doneButtonTapped() {
        print("Done button tapped")
        
        // Immediately disable further interaction to prevent double-taps
        viewBarcodeButton.isUserInteractionEnabled = false
        doneButton.isUserInteractionEnabled = false
        
        // Immediately hide overlay
        successOverlay.alpha = 0
        
        // Clean up resources
        captureSession?.stopRunning()
        scanningLine.layer.removeAllAnimations()
        
        // Navigate directly back to home
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func showAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        present(alert, animated: true)
    }
}
