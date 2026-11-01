import SwiftUI

/// Root screen — same structural pattern as the other games in this
/// portfolio (Domino Yard got this first): language toggle + header up top,
/// a rule-variant picker, primary actions as full-width cards, a utility
/// row for Stats/Rules/Settings, cross-promo at the bottom, and (free tier
/// only) a pinned banner ad below everything. No standalone Premium menu
/// entry (moved into Settings) and no Exit/quit button (Apple Guideline
/// 4.0 risk).
struct ContentView: View {
    @StateObject private var store = StoreManager()
    @ObservedObject private var lang = AppLang.shared
    @State private var options = GameOptions.load()
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
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            languageToggle
                            header
                            variantPicker
                            primaryActions
                            utilityRow
                            CrossPromoSection(accent: brass, textColor: cream, cardFill: Color.white.opacity(0.06))
                        }
                        .padding(20)
                    }
                    if !store.isPremium {
                        BannerAdView().frame(height: 50)
                    }
                }
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(store: store, variant: options.variant)
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
            Text(t("4 rule variants · 2 players", "4 варианта правил · 2 игрока"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(brass)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Variant picker

    private var variantPicker: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(CheckersVariant.allCases, id: \.self) { v in
                    Button {
                        options.variant = v
                        options.save()
                    } label: {
                        Text(variantTitle(v))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(felt.opacity(0.4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(options.variant == v ? brass : cream.opacity(0.15), lineWidth: options.variant == v ? 2 : 1)
                                    )
                            )
                    }
                }
            }
            Text(variantHelp(options.variant))
                .font(.system(size: 12))
                .foregroundStyle(brass.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
    }

    private func variantTitle(_ v: CheckersVariant) -> String {
        switch v {
        case .russian: return t("Russian", "Русские")
        case .giveaway: return t("Giveaway", "Поддавки")
        case .international: return t("International", "Международные")
        case .english: return t("English", "Английские")
        }
    }

    private func variantHelp(_ v: CheckersVariant) -> String {
        switch v {
        case .russian:
            return t("Standard 8×8 draughts. Capture any direction, kings fly.", "Стандартные шашки 8×8. Бой в любую сторону, дамка летает.")
        case .giveaway:
            return t("Same board — but you win by losing all your pieces or getting stuck.", "Та же доска — но побеждает тот, кто лишится всех шашек или не сможет ходить.")
        case .international:
            return t("10×10 board, 20 pieces each. You must play the capture that takes the most pieces.", "Доска 10×10, по 20 шашек. Бить нужно так, чтобы взять максимум шашек.")
        case .english:
            return t("8×8, forward-only capture for men, kings move one square only.", "8×8, бой только вперёд для простых шашек, дамка ходит на одну клетку.")
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
