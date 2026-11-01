import SwiftUI

struct NetMessage: Codable {
var move: Move? = nil
var reset: Bool = false
}

struct GameView: View {
@ObservedObject var store: StoreManager
@ObservedObject private var lang = AppLang.shared
@StateObject private var engine = CheckersEngine()
@State private var isBotThinking = false
@Environment(\.dismiss) private var dismiss

var multiplayer: MultiplayerManager? = nil
var localColor: PieceColor = .white

private let wood = Color(red: 0.16, green: 0.10, blue: 0.06)
private let brass = Color(red: 0.79, green: 0.59, blue: 0.17)
private let cream = Color(red: 0.94, green: 0.90, blue: 0.82)
private let felt = Color(red: 0.11, green: 0.24, blue: 0.17)
private let feltLight = Color(red: 0.86, green: 0.80, blue: 0.64)

var body: some View {
ZStack {
wood.ignoresSafeArea()
VStack(spacing: 16) {
header
boardView
.padding(.horizontal, 12)
footer
Spacer()
}
.padding(.top, 12)
}
.onChange(of: engine.turn) { _ in
botTurnIfNeeded()
}
.onAppear {
setupMultiplayerReceiver()
}
.alert(t("Game Over", "Игра окончена"), isPresented: Binding(get: { engine.winner != nil }, set: { _ in })) {
Button(t("New Game", "Новая игра")) { resetGame() }
Button(t("Menu", "В меню")) { dismiss() }
} message: {
Text(engine.winner == .white ? t("White wins!", "Белые победили!") : t("Black wins!", "Чёрные победили!"))
}
}

private var header: some View {
HStack {
Text("\(t("Black", "Чёрные")): \(engine.pieceCount.black)")
.foregroundStyle(cream)
Spacer()
Text(headerTurnText)
.font(.headline)
.foregroundStyle(brass)
Spacer()
Text("\(t("White", "Белые")): \(engine.pieceCount.white)")
.foregroundStyle(cream)
}
.font(.subheadline)
.padding(.horizontal, 16)
}

private var headerTurnText: String {
if multiplayer != nil {
return engine.turn == localColor ? t("Your Turn", "Ваш ход") : t("Opponent's Turn", "Ход соперника")
}
return engine.turn == .white ? t("Turn: White", "Ход: Белые") : t("Turn: Black (bot)", "Ход: Чёрные (бот)")
}

private var boardView: some View {
GeometryReader { geo in
let size = min(geo.size.width, geo.size.height)
let cell = size / 8

ZStack {
VStack(spacing: 0) {
ForEach(0..<8, id: \.self) { row in
HStack(spacing: 0) {
ForEach(0..<8, id: \.self) { col in
let sq = Square(row: row, col: col)
Rectangle()
.fill(sq.isDark ? felt : feltLight)
.frame(width: cell, height: cell)
.overlay(highlightOverlay(for: sq))
.onTapGesture { handleTap(sq) }
}
}
}
}
.overlay(
Rectangle().stroke(brass, lineWidth: 3)
)

ForEach(Array(engine.board.keys), id: \.self) { sq in
if let piece = engine.board[sq] {
pieceView(piece)
.frame(width: cell * 0.78, height: cell * 0.78)
.position(x: CGFloat(sq.col) * cell + cell / 2, y: CGFloat(sq.row) * cell + cell / 2)
.allowsHitTesting(false)
}
}
}
.frame(width: size, height: size)
}
.aspectRatio(1, contentMode: .fit)
}

private func highlightOverlay(for sq: Square) -> some View {
Group {
if engine.selectedSquare == sq {
Rectangle().fill(brass.opacity(0.45))
} else if engine.legalMovesForSelection.contains(where: { $0.path.last == sq }) {
Circle().fill(brass.opacity(0.55)).padding(14)
}
}
}

private func pieceView(_ piece: Piece) -> some View {
ZStack {
Circle()
.fill(piece.color == .white
? LinearGradient(colors: [cream, Color(white: 0.75)], startPoint: .top, endPoint: .bottom)
: LinearGradient(colors: [Color(white: 0.28), Color.black], startPoint: .top, endPoint: .bottom))
.overlay(Circle().stroke(brass, lineWidth: 2))
.shadow(color: .black.opacity(0.5), radius: 2, y: 2)
if piece.kind == .king {
Image(systemName: "crown.fill")
.foregroundStyle(brass)
.font(.system(size: 14))
}
}
}

private var footer: some View {
HStack(spacing: 16) {
Button {
resetGame()
} label: {
Label(t("New Game", "Новая игра"), systemImage: "arrow.counterclockwise")
}
Spacer()
if let mp = multiplayer {
Text(multiplayerStatusText(mp))
.font(.caption)
.foregroundStyle(cream.opacity(0.6))
} else if !store.isPremium {
Text(t("Ads shown in the free version", "Реклама в бесплатной версии"))
.font(.caption)
.foregroundStyle(cream.opacity(0.5))
}
}
.foregroundStyle(cream)
.padding(.horizontal, 18)
}

private func multiplayerStatusText(_ mp: MultiplayerManager) -> String {
if case .connected(let name) = mp.state {
return "\(t("Connected", "Подключено")): \(name)"
}
return t("Connection lost", "Соединение прервано")
}

private func handleTap(_ sq: Square) {
guard engine.winner == nil, !isBotThinking else { return }
if let mp = multiplayer {
guard engine.turn == localColor else { return }
let pendingMove = engine.legalMovesForSelection.first(where: { $0.path.last == sq })
engine.tap(sq)
if let move = pendingMove {
mp.send(NetMessage(move: move))
}
} else {
guard engine.turn == .white else { return }
engine.tap(sq)
}
}

private func botTurnIfNeeded() {
guard multiplayer == nil else { return }
guard engine.turn == .black, engine.winner == nil, !isBotThinking else { return }
isBotThinking = true
DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
if let move = engine.botMove(for: .black) {
engine.apply(move)
}
isBotThinking = false
}
}

private func resetGame() {
engine.reset()
multiplayer?.send(NetMessage(reset: true))
}

private func setupMultiplayerReceiver() {
guard let mp = multiplayer else { return }
mp.onReceive = { data in
guard let msg = try? JSONDecoder().decode(NetMessage.self, from: data) else { return }
DispatchQueue.main.async {
if msg.reset {
engine.reset()
} else if let move = msg.move {
engine.apply(move)
}
}
}
}
}

struct PremiumView: View {
@ObservedObject var store: StoreManager
@ObservedObject private var lang = AppLang.shared
@Environment(\.dismiss) private var dismiss

private let brass = Color(red: 0.79, green: 0.59, blue: 0.17)

var body: some View {
NavigationStack {
VStack(spacing: 24) {
Image(systemName: "crown.fill")
.font(.system(size: 48))
.foregroundStyle(brass)
.padding(.top, 24)

Text("Checkers Club Premium")
.font(.title2.bold())

VStack(alignment: .leading, spacing: 12) {
featureRow(t("No ads", "Без рекламы"))
featureRow(t("Local multiplayer over Wi-Fi/Bluetooth", "Локальный мультиплеер по Wi-Fi/Bluetooth"))
featureRow(t("One-time purchase — forever", "Разовая покупка — навсегда"))
}
.padding(.horizontal, 24)

if store.isPremium {
Label(t("Premium already active", "Premium уже активен"), systemImage: "checkmark.seal.fill")
.foregroundStyle(.green)
} else {
Button {
Task { await store.purchasePremium() }
} label: {
Text("\(t("Buy for", "Купить за")) \(store.priceText)")
.fontWeight(.bold)
.frame(maxWidth: .infinity)
.padding()
.background(brass)
.foregroundStyle(.black)
.clipShape(RoundedRectangle(cornerRadius: 14))
}
.padding(.horizontal, 24)

Button(t("Restore Purchases", "Восстановить покупки")) {
Task { await store.restorePurchases() }
}
.font(.footnote)
}

if let err = store.purchaseErrorMessage {
Text(err).font(.caption).foregroundStyle(.red)
}

Spacer()
}
.toolbar {
ToolbarItem(placement: .cancellationAction) {
Button(t("Close", "Закрыть")) { dismiss() }
}
}
}
}

private func featureRow(_ text: String) -> some View {
HStack {
Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
Text(text)
}
}
}

#Preview {
GameView(store: StoreManager())
}
