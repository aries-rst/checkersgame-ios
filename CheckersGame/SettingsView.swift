import SwiftUI

/// Real settings screen, pushed from the root screen's "Settings" button.
struct SettingsView: View {
    @ObservedObject var store: StoreManager
    @ObservedObject private var lang = AppLang.shared
    @State private var showPremium = false
    @State private var statsResetConfirmed = false

    private let wood = Color(red: 0.16, green: 0.10, blue: 0.06)
    private let brass = Color(red: 0.79, green: 0.59, blue: 0.17)
    private let cream = Color(red: 0.94, green: 0.90, blue: 0.82)
    private let felt = Color(red: 0.11, green: 0.24, blue: 0.17)

    var body: some View {
        ZStack {
            wood.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    languageRow
                    premiumRow
                    statusFooter
                    resetStatsRow
                }
                .padding(20)
            }
        }
        .navigationTitle(t("Settings", "Настройки"))
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPremium) {
            PremiumView(store: store)
        }
    }

    private var languageRow: some View {
        settingsCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("Language", "Язык"))
                        .font(.subheadline.bold())
                        .foregroundStyle(cream)
                    Text(lang.isRussian ? t("Russian", "Русский") : t("English", "Английский"))
                        .font(.caption)
                        .foregroundStyle(cream.opacity(0.7))
                }
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
    }

    private var premiumRow: some View {
        settingsCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: store.isPremium ? "crown.fill" : "crown")
                            .foregroundStyle(brass)
                        Text(store.isPremium ? t("Premium Active", "Premium активен") : "Premium")
                            .font(.subheadline.bold())
                            .foregroundStyle(cream)
                    }
                    if !store.isPremium {
                        Text(t("Removes ads · unlocks local multiplayer", "Убирает рекламу · открывает локальный мультиплеер"))
                            .font(.caption)
                            .foregroundStyle(cream.opacity(0.7))
                    }
                }
                Spacer()
                if store.isPremium {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(brass)
                        .font(.system(size: 20))
                } else {
                    Button {
                        showPremium = true
                    } label: {
                        Text(store.priceText)
                            .fontWeight(.semibold)
                            .foregroundStyle(wood)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(brass))
                    }
                }
            }
        }
    }

    private var statusFooter: some View {
        Text(store.isPremium
             ? t("Ads disabled · Local multiplayer unlocked", "Реклама отключена · Локальный мультиплеер открыт")
             : t("Free version · with ads", "Бесплатная версия · с рекламой"))
            .font(.footnote)
            .foregroundStyle(cream.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    private var resetStatsRow: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(t("Statistics", "Статистика"))
                    .font(.subheadline.bold())
                    .foregroundStyle(cream)
                Button {
                    GameStats.reset()
                    statsResetConfirmed = true
                } label: {
                    Text(statsResetConfirmed ? t("Stats Reset", "Статистика сброшена") : t("Reset Stats", "Сбросить статистику"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.red.opacity(0.85))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(felt.opacity(0.25))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.5), lineWidth: 1))
                        )
                }
            }
        }
    }

    private func settingsCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(felt.opacity(0.35))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(cream.opacity(0.12), lineWidth: 1))
            )
    }
}

#Preview {
    NavigationStack { SettingsView(store: StoreManager()) }
}
