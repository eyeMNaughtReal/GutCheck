import Foundation

class LocalStorageService {
    static let shared = LocalStorageService()
    
    private init() {}
    
    func clearAllData() async throws {
        // Clear any local files in document directory
        try clearDocumentDirectory()
    }
    
    private func clearDocumentDirectory() throws {
        let fileManager = FileManager.default
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let files = try fileManager.contentsOfDirectory(atPath: documentPath)
        
        for file in files {
            let filePath = (documentPath as NSString).appendingPathComponent(file)
            try fileManager.removeItem(atPath: filePath)
        }
    }
}
