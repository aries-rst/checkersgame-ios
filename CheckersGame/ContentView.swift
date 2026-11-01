import SwiftUI

/// Root screen — same structural pattern as the other 4 games in this
/// portfolio (Domino Yard got this first): language toggle + header up top,
/// primary actions as full-width cards, a utility row for Stats/Rules/
/// Settings, cross-promo at the bottom. No standalone Premium menu entry
/// (moved into Settings) and no Exit/quit button (Apple Guideline 4.0 risk).
struct ContentView: View {
    @StateObject private var store = StoreManager()
    @ObservedObject private var lang = AppLang.shared
    @State private var showGame = false
    @State private var showLobby = false
    @State private var showPremium = false
    @State private var showStats = false
    @State private var showRules = false
    @State private var showSettings = false

    private let wood = Color(red: 0.16, green: 0.10, blue: 0.06)
    private let brass = Color(red: 0.79, green: 0.59, blue: 0.17)
    private let cream = Color(red: 0.94, green: 0.90, blue: 0.82)
    private let felt = Color(red: 0.11, green: 0.24, blue: 0.17)

    var body: some View {
        NavigationStack {
            ZStack {
                wood.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        languageToggle
                        header
                        primaryActions
                        utilityRow
                        CrossPromoSection(accent: brass, textColor: cream, cardFill: Color.white.opacity(0.06))
                    }
                    .padding(20)
                }
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(store: store)
            }
            .navigationDestination(isPresented: $showLobby) {
                MultiplayerLobbyView(store: store)
            }
            .navigationDestination(isPresented: $showStats) {
                StatsView()
            }
            .navigationDestination(isPresented: $showRules) {
                RulesView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(store: store)
            }
            .sheet(isPresented: $showPremium) {
                PremiumView(store: store)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var languageToggle: some View {
        HStack {
            Spacer()
            Button {
                AppLang.shared.isRussian.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                    Text(lang.isRussian ? "EN" : "RU")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundStyle(cream)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(brass.opacity(0.6), lineWidth: 1))
                )
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkerboard.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(brass)
            Text("CHECKERS CLUB")
                .font(.system(size: 28, weight: .heavy, design: .serif))
                .foregroundStyle(cream)
                .tracking(2)
            Text(t("Russian Draughts · Mandatory capture · Flying kings", "Русские шашки · Обязательный бой · Дамка летает"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(brass)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Primary actions

    private var primaryActions: some View {
        VStack(spacing: 14) {
            Button {
                showGame = true
            } label: {
                menuLabel(t("Play vs Bot", "Играть с ботом"), system: "person.fill.checkmark", filled: true)
            }

            Button {
                if store.isPremium {
                    showLobby = true
                } else {
                    showPremium = true
                }
            } label: {
                menuLabel(t("Play Nearby (Wi-Fi/Bluetooth)", "Игра рядом (Wi-Fi/Bluetooth)"), system: "antenna.radiowaves.left.and.right", filled: false)
            }
        }
    }

    private func menuLabel(_ text: String, system: String, filled: Bool) -> some View {
        HStack {
            Image(systemName: system)
            Text(text).fontWeight(.semibold)
            Spacer()
            if !filled {
                Image(systemName: "chevron.right").font(.caption)
            }
        }
        .foregroundStyle(filled ? wood : cream)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(filled ? brass : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(brass.opacity(filled ? 0 : 0.5), lineWidth: 1)
                )
        )
    }

    // MARK: - Utility row

    private var utilityRow: some View {
        HStack(spacing: 12) {
            smallActionButton(t("Stats", "Статистика"), system: "chart.bar.fill") { showStats = true }
            smallActionButton(t("Rules", "Правила"), system: "book.fill") { showRules = true }
            smallActionButton(t("Settings", "Настройки"), system: "gearshape.fill") { showSettings = true }
        }
    }

    private func smallActionButton(_ title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: system)
                Text(title).font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(cream)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(felt.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(cream.opacity(0.15), lineWidth: 1))
            )
        }
    }
}

#Preview {
    ContentView()
}
