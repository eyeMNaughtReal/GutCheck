import Testing
import UIKit
@testable import GutCheck

struct ImageCompressionUtilityTests {

    /// Creates a simple test image for compression tests
    private func makeTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Compression with quality level

    @Test("Compresses image with standard quality")
    func compressesStandard() throws {
        let image = makeTestImage()
        let data = try ImageCompressionUtility.compress(image, quality: .standard)
        #expect(!data.isEmpty)
    }

    @Test("Lower quality produces smaller data")
    func lowerQualitySmaller() throws {
        let image = makeTestImage(size: CGSize(width: 500, height: 500))
        let lowData = try ImageCompressionUtility.compress(image, quality: .low)
        let highData = try ImageCompressionUtility.compress(image, quality: .high)
        #expect(lowData.count <= highData.count)
    }

    @Test("All CompressionQuality levels produce valid data")
    func allQualityLevels() throws {
        let image = makeTestImage()
        let qualities: [ImageCompressionUtility.CompressionQuality] = [.low, .medium, .standard, .high, .maximum]
        for quality in qualities {
            let data = try ImageCompressionUtility.compress(image, quality: quality)
            #expect(!data.isEmpty)
        }
    }

    // MARK: - Custom quality compression

    @Test("Compresses with custom CGFloat quality")
    func compressesCustomQuality() throws {
        let image = makeTestImage()
        let data = try ImageCompressionUtility.compress(image, quality: CGFloat(0.5))
        #expect(!data.isEmpty)
    }

    @Test("Throws for quality below 0.0")
    func throwsForNegativeQuality() {
        let image = makeTestImage()
        #expect(throws: ImageCompressionError.invalidQuality) {
            try ImageCompressionUtility.compress(image, quality: CGFloat(-0.1))
        }
    }

    @Test("Throws for quality above 1.0")
    func throwsForExcessiveQuality() {
        let image = makeTestImage()
        #expect(throws: ImageCompressionError.invalidQuality) {
            try ImageCompressionUtility.compress(image, quality: CGFloat(1.5))
        }
    }

    @Test("Accepts boundary quality 0.0")
    func acceptsZeroQuality() throws {
        let image = makeTestImage()
        let data = try ImageCompressionUtility.compress(image, quality: CGFloat(0.0))
        #expect(!data.isEmpty)
    }

    @Test("Accepts boundary quality 1.0")
    func acceptsOneQuality() throws {
        let image = makeTestImage()
        let data = try ImageCompressionUtility.compress(image, quality: CGFloat(1.0))
        #expect(!data.isEmpty)
    }

    // MARK: - Target size compression

    @Test("Compresses to target size")
    func compressesToTargetSize() throws {
        let image = makeTestImage(size: CGSize(width: 500, height: 500))
        let data = try ImageCompressionUtility.compressToTargetSize(image, targetSizeKB: 100)
        #expect(!data.isEmpty)
    }

    // MARK: - File size estimation

    @Test("Estimates file size for image")
    func estimatesFileSize() {
        let image = makeTestImage()
        let size = ImageCompressionUtility.estimateFileSize(for: image, at: .standard)
        #expect(size != nil)
        #expect(size! > 0)
    }

    // MARK: - CompressionQuality values

    @Test("CompressionQuality values are in expected range")
    func compressionQualityValues() {
        #expect(ImageCompressionUtility.CompressionQuality.low.value == 0.3)
        #expect(ImageCompressionUtility.CompressionQuality.medium.value == 0.6)
        #expect(ImageCompressionUtility.CompressionQuality.standard.value == 0.8)
        #expect(ImageCompressionUtility.CompressionQuality.high.value == 0.9)
        #expect(ImageCompressionUtility.CompressionQuality.maximum.value == 1.0)
    }

    // MARK: - ImageCompressionError descriptions

    @Test("Error descriptions are non-empty")
    func errorDescriptions() {
        #expect(ImageCompressionError.compressionFailed.errorDescription != nil)
        #expect(ImageCompressionError.invalidQuality.errorDescription != nil)
        #expect(ImageCompressionError.targetSizeNotAchievable.errorDescription != nil)
    }
}
