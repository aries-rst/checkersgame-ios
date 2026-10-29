import SwiftUI

// Club palette — dark wood, brass, felt green.
// Deliberately distinct from ChessPuzzleDaily's ivory-knight/espresso look
// and from the other board games' planned palettes (Nardy: ochre/copper,
// Domino: poster primaries, Durak: burgundy/gold).
enum ClubPalette {
    static let wood = Color(red: 0.12, green: 0.08, blue: 0.05)
    static let felt = Color(red: 0.07, green: 0.20, blue: 0.12)
    static let brass = Color(red: 0.78, green: 0.62, blue: 0.29)
    static let cream = Color(red: 0.93, green: 0.88, blue: 0.78)
}

struct ContentView: View {
    var body: some View {
        ZStack {
            ClubPalette.wood.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("CHECKERS CLUB")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(ClubPalette.brass)
                Text("Шашки — задача дня · Турнир двора")
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(ClubPalette.cream.opacity(0.8))
                RoundedRectangle(cornerRadius: 12)
                    .fill(ClubPalette.felt)
                    .frame(width: 220, height: 220)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ClubPalette.brass, lineWidth: 3)
                    )
                    .overlay(Text("Board scaffold").foregroundStyle(ClubPalette.cream.opacity(0.5)))
            }
        }
    }
}

#Preview {
    ContentView()
}
