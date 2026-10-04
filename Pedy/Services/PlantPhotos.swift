import UIKit

enum PlantPhotos {
    static var directory: URL {
        URL.applicationSupportDirectory.appendingPathComponent("PlantPhotos", isDirectory: true)
    }

    static func jpeg(_ image: UIImage, side: CGFloat = 768) throws -> Data {
        let scale = min(1, side / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = rendered.jpegData(compressionQuality: 0.7) else { throw LocalPlantAIError.invalidImage }
        return data
    }

    static func save(_ image: UIImage) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = UUID().uuidString + ".jpg"
        try jpeg(image).write(to: directory.appendingPathComponent(filename), options: .atomic)
        return filename
    }

    static func image(_ filename: String?) -> UIImage? {
        guard let filename, filename == URL(fileURLWithPath: filename).lastPathComponent else { return nil }
        return UIImage(contentsOfFile: directory.appendingPathComponent(filename).path)
    }

    static func remove(_ filename: String?) {
        guard let filename, filename == URL(fileURLWithPath: filename).lastPathComponent else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }
}
