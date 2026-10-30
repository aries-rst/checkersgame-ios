import SwiftUI

struct ContentView: View {
    @StateObject private var store = StoreManager()
    @State private var showGame = false
    @State private var showPremium = false

    private let wood = Color(red: 0.16, green: 0.10, blue: 0.06)
    private let brass = Color(red: 0.79, green: 0.59, blue: 0.17)
    private let cream = Color(red: 0.94, green: 0.90, blue: 0.82)

    var body: some View {
        NavigationStack {
            ZStack {
                wood.ignoresSafeArea()
                VStack(spacing: 28) {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "checkerboard.rectangle")
                            .font(.system(size: 54))
                            .foregroundStyle(brass)
                        Text("CHECKERS CLUB")
                            .font(.system(size: 30, weight: .heavy, design: .serif))
                            .foregroundStyle(cream)
                            .tracking(2)
                        Text("Русские шашки")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(brass)
                    }

                    VStack(spacing: 14) {
                        Button {
                            showGame = true
                        } label: {
                            menuLabel("Играть с ботом", system: "person.fill.checkmark")
                        }

                        Button {
                            showPremium = true
                        } label: {
                            menuLabel(store.isPremium ? "Premium активен" : "Premium — \(store.priceText)", system: store.isPremium ? "crown.fill" : "crown")
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Text(store.isPremium ? "Реклама отключена · Локальный мультиплеер открыт" : "Бесплатная версия · с рекламой")
                        .font(.footnote)
                        .foregroundStyle(cream.opacity(0.6))
                        .padding(.bottom, 24)
                }
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(store: store)
            }
            .sheet(isPresented: $showPremium) {
                PremiumView(store: store)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func menuLabel(_ text: String, system: String) -> some View {
        HStack {
            Image(systemName: system)
            Text(text)
                .fontWeight(.semibold)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
        }
        .foregroundStyle(cream)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(brass.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ContentView()
}
