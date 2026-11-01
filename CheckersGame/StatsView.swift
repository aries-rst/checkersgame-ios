import SwiftUI

/// Lightweight local match-result tracker, persisted via UserDefaults.
/// `GameView` calls `GameStats.record(...)` once per finished vs-bot game
/// (no tracking for Nearby multiplayer games, same as the other apps in
/// this portfolio — only the human's own result against the bot is scored).
struct GameStats: Codable {
    var played: Int = 0
    var won: Int = 0

    private static let key = "checkers.gameStats.v1"

    static func load() -> GameStats {
        guard let data = UserDefaults.standard.data(forKey: key),
              let s = try? JSONDecoder().decode(GameStats.self, from: data) else {
            return GameStats()
        }
        return s
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    static func record(won: Bool) {
        var s = load()
        s.played += 1
        if won { s.won += 1 }
        s.save()
    }

    static func reset() {
        GameStats().save()
    }
}

/// Real stats screen, pushed from the root screen's "Stats" button.
struct StatsView: View {
    @ObservedObject private var lang = AppLang.shared
    @State private var stats = GameStats.load()

    private let wood = Color(red: 0.16, green: 0.10, blue: 0.06)
    private let brass = Color(red: 0.79, green: 0.59, blue: 0.17)
    private let cream = Color(red: 0.94, green: 0.90, blue: 0.82)
    private let felt = Color(red: 0.11, green: 0.24, blue: 0.17)

    private var winRateText: String {
        guard stats.played > 0 else { return "—" }
        let pct = Int((Double(stats.won) / Double(stats.played) * 100).rounded())
        return "\(pct)%"
    }

    var body: some View {
        ZStack {
            wood.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 12) {
                        statTile(t("Played", "Сыграно"), value: "\(stats.played)")
                        statTile(t("Won", "Побед"), value: "\(stats.won)")
                        statTile(t("Win Rate", "Процент побед"), value: winRateText)
                    }

                    Button {
                        GameStats.reset()
                        stats = GameStats.load()
                    } label: {
                        Text(t("Reset Stats", "Сбросить статистику"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.red.opacity(0.85))
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(felt.opacity(0.3))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.red.opacity(0.5), lineWidth: 1))
                            )
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(t("Stats", "Статистика"))
        .preferredColorScheme(.dark)
        .onAppear {
            stats = GameStats.load()
        }
    }

    private func statTile(_ label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(brass)
            Text(label)
                .font(.caption)
                .foregroundStyle(cream.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(felt.opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(cream.opacity(0.15), lineWidth: 1))
        )
    }
}

#Preview {
    NavigationStack { StatsView() }
}
