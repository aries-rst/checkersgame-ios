import Foundation

/// Persisted user choice of rule variant, UserDefaults-backed (same
/// lightweight pattern as `AppLang`).
struct GameOptions: Codable {
    var variant: CheckersVariant = .russian

    private static let key = "checkers.gameOptions.v1"

    static func load() -> GameOptions {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(GameOptions.self, from: data) else {
            return GameOptions()
        }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
