import Foundation

class BarcodeManager {
    
    // MARK: - Singleton
    
    static let shared = BarcodeManager()
    private init() {}
    
    // MARK: - Constants
    
    private let barcodeKey = "com.teamdiscount.storedBarcode"
    
    // MARK: - Public Methods
    
    /// Saves an EAN-13 barcode to persistent storage
    /// - Parameter barcode: The EAN-13 barcode string to save
    func saveBarcode(_ barcode: String) {
        // Validate the barcode format (EAN-13 is 13 digits)
        guard barcode.count == 13,
              barcode.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            print("Invalid EAN-13 format. Must be 13 digits.")
            return
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(barcode, forKey: barcodeKey)
    }
    
    /// Retrieves the stored barcode if available
    /// - Returns: The EAN-13 barcode string or nil if none is stored
    func getStoredBarcode() -> String? {
        return UserDefaults.standard.string(forKey: barcodeKey)
    }
    
    /// Checks if a barcode is currently stored
    /// - Returns: True if a barcode is stored, false otherwise
    func hasStoredBarcode() -> Bool {
        return getStoredBarcode() != nil
    }
    
    /// Deletes the stored barcode
    func deleteStoredBarcode() {
        UserDefaults.standard.removeObject(forKey: barcodeKey)
        // Post notification that barcode was deleted
        NotificationCenter.default.post(name: NSNotification.Name("BarcodeDeleted"), object: nil)
    }
}
