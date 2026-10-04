import SwiftData

enum PlantDeletion {
    static func delete(_ plant: Plant, events: [CareEvent], in context: ModelContext) throws {
        let photo = plant.photoFilename
        events.filter { $0.plantID == plant.id }.forEach { context.delete($0) }
        context.delete(plant)
        do {
            try context.save()
            PlantPhotos.remove(photo)
        } catch {
            context.rollback()
            throw error
        }
    }
}
