import SwiftUI

/// Rules reference for Russian draughts, pushed from the root screen's
/// "Rules" button.
struct RulesView: View {
    @ObservedObject private var lang = AppLang.shared

    private let wood = Color(red: 0.16, green: 0.10, blue: 0.06)
    private let brass = Color(red: 0.79, green: 0.59, blue: 0.17)
    private let cream = Color(red: 0.94, green: 0.90, blue: 0.82)
    private let felt = Color(red: 0.11, green: 0.24, blue: 0.17)

    var body: some View {
        ZStack {
            wood.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ruleSection(
                        title: t("The Board & Setup", "Доска и расстановка"),
                        body: t(
                            "Played on the dark squares of an 8×8 board. Each side starts with 12 men on the three rows closest to them. White moves first, and turns alternate after that.",
                            "Играют на тёмных клетках доски 8×8. У каждой стороны по 12 простых шашек на трёх ближних рядах. Первый ход — за белыми, дальше ходы чередуются."
                        )
                    )
                    ruleSection(
                        title: t("Moving", "Ход"),
                        body: t(
                            "A man moves one square diagonally forward onto an empty square. A king (see below) may move any number of empty squares diagonally, in any direction.",
                            "Простая шашка ходит на одну клетку по диагонали вперёд на свободное поле. Дамка (см. ниже) может ходить на любое число свободных клеток по диагонали в любом направлении."
                        )
                    )
                    ruleSection(
                        title: t("Capturing Is Mandatory", "Бой обязателен"),
                        body: t(
                            "If you have any legal capture available, you must take it — you can't make a quiet move instead. A man captures by jumping over an adjacent enemy piece into the empty square right behind it, in any of the four diagonal directions (not just forward). If another capture is available from the landing square, the same piece keeps jumping in one turn. When more than one capturing line is available, Russian rules let you choose which one to play, even if it captures fewer pieces.",
                            "Если есть возможность взять шашку соперника, бить обязательно — тихий ход вместо боя делать нельзя. Простая шашка бьёт, перепрыгивая через соседнюю шашку соперника на свободное поле сразу за ней, в любом из четырёх диагональных направлений (не только вперёд). Если с нового поля возможен ещё один бой, та же шашка продолжает бить в этом же ходу. Если возможно несколько вариантов боя, по русским правилам можно выбрать любой из них, даже если он бьёт меньше шашек."
                        )
                    )
                    ruleSection(
                        title: t("Kings (\"Flying Kings\")", "Дамки («летающая дамка»)"),
                        body: t(
                            "A man that reaches the farthest row becomes a king. A king moves and captures along the whole open diagonal, not just one square — it can land on any empty square beyond a captured piece, as long as every square it passes over and lands on is empty until the capture.",
                            "Простая шашка, дошедшая до последнего ряда, становится дамкой. Дамка ходит и бьёт по всей открытой диагонали, а не на одну клетку — после боя может остановиться на любом свободном поле за срубленной шашкой, если все клетки на пути свободны вплоть до боя."
                        )
                    )
                    ruleSection(
                        title: t("Winning", "Победа"),
                        body: t(
                            "You win by capturing all of your opponent's pieces, or by leaving them with no legal move on their turn.",
                            "Победа присуждается, если взяты все шашки соперника, либо если на своём ходу у соперника не остаётся ни одного допустимого хода."
                        )
                    )
                }
                .padding(20)
            }
        }
        .navigationTitle(t("Rules", "Правила"))
        .preferredColorScheme(.dark)
    }

    private func ruleSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(brass)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(cream.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(felt.opacity(0.35))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(brass.opacity(0.3), lineWidth: 1))
        )
    }
}

#Preview {
    NavigationStack { RulesView() }
}
