import XCTest
import UIKit
@testable import Pedy

final class PlantPhotosTests: XCTestCase {
    func testPhotoPersistsAndIsDownsized() throws {
        let input = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 800)).image { context in
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 800))
        }
        let filename = try PlantPhotos.save(input)
        defer { PlantPhotos.remove(filename) }
        let image = try XCTUnwrap(PlantPhotos.image(filename))
        XCTAssertEqual(image.cgImage?.width, 768)
        XCTAssertEqual(image.cgImage?.height, 512)
        PlantPhotos.remove(filename)
        XCTAssertNil(PlantPhotos.image(filename))
    }

    func testMissingAndInvalidPhotoPathsDoNotBreakOldPlants() {
        XCTAssertNil(PlantPhotos.image(nil))
        XCTAssertNil(PlantPhotos.image("../private.jpg"))
        XCTAssertNil(PlantPhotos.image("missing.jpg"))
    }
}
