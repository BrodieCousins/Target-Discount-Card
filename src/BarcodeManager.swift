import Foundation

class BarcodeManager {
    // MARK: - Properties
    
    static let shared = BarcodeManager()
    
    private let userDefaultsKey = "storedBarcode"
    private let lastScannedDateKey = "lastScannedDate"
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer to ensure singleton usage
    }
    
    // MARK: - Public Methods
    
    /// Saves a barcode to persistent storage
    /// - Parameter barcodeString: The barcode string to save
    func saveBarcode(_ barcodeString: String) {
        UserDefaults.standard.set(barcodeString, forKey: userDefaultsKey)
        UserDefaults.standard.set(Date(), forKey: lastScannedDateKey)
        
        // Post notification so other parts of the app can update
        NotificationCenter.default.post(name: .barcodeDidUpdate, object: nil)
    }
    
    /// Retrieves the stored barcode if available
    /// - Returns: The barcode string or nil if none stored
    func getStoredBarcode() -> String? {
        return UserDefaults.standard.string(forKey: userDefaultsKey)
    }
    
    /// Checks if a barcode is currently stored
    /// - Returns: True if a barcode exists, false otherwise
    func hasStoredBarcode() -> Bool {
        return getStoredBarcode() != nil
    }
    
    /// Deletes the stored barcode
    func deleteStoredBarcode() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: lastScannedDateKey)
        
        // Post notification so other parts of the app can update
        NotificationCenter.default.post(name: .barcodeDidUpdate, object: nil)
    }
    
    /// Gets the date when the barcode was last scanned
    /// - Returns: Date when barcode was last scanned, or nil if no date stored
    func getLastScannedDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastScannedDateKey) as? Date
    }
    
    /// Formats an EAN-13 barcode string with proper separators
    /// - Parameter code: The raw barcode string
    /// - Returns: Formatted barcode string
    func formatEAN13(_ code: String) -> String {
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
}

// MARK: - Notification Extensions

extension Notification.Name {
    /// Notification sent when a barcode is updated or deleted
    static let barcodeDidUpdate = Notification.Name("barcodeDidUpdate")
}
