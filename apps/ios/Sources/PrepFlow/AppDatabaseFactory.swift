import Foundation
import PrepFlowData

enum AppDatabaseFactory {
    static func makeDatabase() -> PrepFlowDatabase? {
        guard let directory = try? applicationSupportDirectory() else {
            return try? PrepFlowDatabase()
        }
        return try? PrepFlowDatabase(path: directory.appendingPathComponent("prepflow.sqlite").path)
    }

    private static func applicationSupportDirectory() throws -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = root.appendingPathComponent("PrepFlow", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
