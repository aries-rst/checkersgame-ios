import Foundation

enum PieceColor: String, Codable, Equatable {
case white
case black

var opposite: PieceColor { self == .white ? .black : .white }
}

enum PieceKind: String, Codable {
case man
case king
}

struct Piece: Identifiable, Codable, Equatable {
let id: UUID
var color: PieceColor
var kind: PieceKind

init(color: PieceColor, kind: PieceKind = .man) {
self.id = UUID()
self.color = color
self.kind = kind
}
}

struct Square: Hashable, Codable {
var row: Int // 0...7, row 0 = Black's back rank
var col: Int // 0...7

var isDark: Bool { (row + col) % 2 == 1 }
}

struct Move: Codable {
var path: [Square] // full sequence of squares visited, path[0] = start
var captured: [Square] // squares of captured pieces, in order
var promotesToKing: Bool

var isCapture: Bool { !captured.isEmpty }
}

/// Russian draughts (шашки) engine: 8x8 board, mandatory capture, omnidirectional
/// capture for men, flying kings.
final class CheckersEngine: ObservableObject {
@Published var board: [Square: Piece] = [:]
@Published var turn: PieceColor = .white
@Published var winner: PieceColor? = nil
@Published var lastMove: Move? = nil
@Published var selectedSquare: Square? = nil
@Published var legalMovesForSelection: [Move] = []

var whiteCaptured = 0
var blackCaptured = 0

init() {
reset()
}

func reset() {
board.removeAll()
turn = .white
winner = nil
lastMove = nil
selectedSquare = nil
legalMovesForSelection = []
whiteCaptured = 0
blackCaptured = 0

for row in 0..<8 {
for col in 0..<8 {
let sq = Square(row: row, col: col)
guard sq.isDark else { continue }
if row <= 2 {
board[sq] = Piece(color: .black)
} else if row >= 5 {
board[sq] = Piece(color: .white)
}
}
}
}

// MARK: - Move generation

private func allDirections() -> [(Int, Int)] {
[(-1, -1), (-1, 1), (1, -1), (1, 1)]
}

private func forwardDirections(for color: PieceColor) -> [(Int, Int)] {
color == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)]
}

func allLegalMoves(for color: PieceColor) -> [Move] {
var captureMoves: [Move] = []
for (square, piece) in board where piece.color == color {
captureMoves.append(contentsOf: captureSequences(from: square, piece: piece, board: board))
}
if !captureMoves.isEmpty {
return captureMoves
}

var simpleMoves: [Move] = []
for (square, piece) in board where piece.color == color {
simpleMoves.append(contentsOf: simpleMovesFrom(square: square, piece: piece))
}
return simpleMoves
}

private func simpleMovesFrom(square: Square, piece: Piece) -> [Move] {
var moves: [Move] = []
if piece.kind == .man {
for (dr, dc) in forwardDirections(for: piece.color) {
let to = Square(row: square.row + dr, col: square.col + dc)
if isOnBoard(to), board[to] == nil {
moves.append(Move(path: [square, to], captured: [], promotesToKing: willPromote(color: piece.color, row: to.row)))
}
}
} else {
for (dr, dc) in allDirections() {
var r = square.row + dr
var c = square.col + dc
while isOnBoard(Square(row: r, col: c)), board[Square(row: r, col: c)] == nil {
moves.append(Move(path: [square, Square(row: r, col: c)], captured: [], promotesToKing: false))
r += dr
c += dc
}
}
}
return moves
}

private func captureSequences(from square: Square, piece: Piece, board: [Square: Piece]) -> [Move] {
var results: [Move] = []
if piece.kind == .man {
manCaptures(square: square, piece: piece, board: board, path: [square], captured: [], results: &results)
} else {
kingCaptures(square: square, piece: piece, board: board, path: [square], captured: [], results: &results)
}
return results
}

private func manCaptures(square: Square, piece: Piece, board: [Square: Piece], path: [Square], captured: [Square], results: inout [Move]) {
var foundFurther = false
for (dr, dc) in allDirections() {
let overSq = Square(row: square.row + dr, col: square.col + dc)
let landSq = Square(row: square.row + dr * 2, col: square.col + dc * 2)
guard isOnBoard(landSq), isOnBoard(overSq) else { continue }
guard let overPiece = board[overSq], overPiece.color != piece.color else { continue }
guard board[landSq] == nil, !captured.contains(overSq) else { continue }

foundFurther = true
var nextBoard = board
nextBoard[square] = nil
nextBoard[landSq] = piece
var nextCaptured = captured
nextCaptured.append(overSq)
var nextPath = path
nextPath.append(landSq)

manCaptures(square: landSq, piece: piece, board: nextBoard, path: nextPath, captured: nextCaptured, results: &results)
}
if !foundFurther && !captured.isEmpty {
results.append(Move(path: path, captured: captured, promotesToKing: willPromote(color: piece.color, row: square.row)))
}
}

private func kingCaptures(square: Square, piece: Piece, board: [Square: Piece], path: [Square], captured: [Square], results: inout [Move]) {
var foundFurther = false
for (dr, dc) in allDirections() {
var r = square.row + dr
var c = square.col + dc
var enemySquare: Square? = nil
while isOnBoard(Square(row: r, col: c)) {
let sq = Square(row: r, col: c)
if let occ = board[sq] {
if occ.color != piece.color && !captured.contains(sq) {
enemySquare = sq
}
break
}
r += dr
c += dc
}
guard let enemy = enemySquare else { continue }
var lr = enemy.row + dr
var lc = enemy.col + dc
while isOnBoard(Square(row: lr, col: lc)), board[Square(row: lr, col: lc)] == nil {
let landSq = Square(row: lr, col: lc)
foundFurther = true
var nextBoard = board
nextBoard[square] = nil
nextBoard[landSq] = piece
var nextCaptured = captured
nextCaptured.append(enemy)
var nextPath = path
nextPath.append(landSq)
kingCaptures(square: landSq, piece: piece, board: nextBoard, path: nextPath, captured: nextCaptured, results: &results)
lr += dr
lc += dc
}
}
if !foundFurther && !captured.isEmpty {
results.append(Move(path: path, captured: captured, promotesToKing: false))
}
}

private func willPromote(color: PieceColor, row: Int) -> Bool {
(color == .white && row == 0) || (color == .black && row == 7)
}

private func isOnBoard(_ sq: Square) -> Bool {
sq.row >= 0 && sq.row < 8 && sq.col >= 0 && sq.col < 8
}

// MARK: - Interaction

func tap(_ square: Square) {
guard winner == nil else { return }

if let move = legalMovesForSelection.first(where: { $0.path.last == square }) {
apply(move)
return
}

guard let piece = board[square], piece.color == turn else {
selectedSquare = nil
legalMovesForSelection = []
return
}

let movesForPiece = allLegalMoves(for: turn).filter { $0.path.first == square }
if movesForPiece.isEmpty {
selectedSquare = nil
legalMovesForSelection = []
return
}
selectedSquare = square
legalMovesForSelection = movesForPiece
}

func apply(_ move: Move) {
guard var piece = board[move.path.first!] else { return }
board[move.path.first!] = nil
for sq in move.captured {
board[sq] = nil
}
if move.promotesToKing {
piece.kind = .king
}
board[move.path.last!] = piece

if move.isCapture {
if piece.color == .white { whiteCaptured += move.captured.count }
else { blackCaptured += move.captured.count }
}

lastMove = move
selectedSquare = nil
legalMovesForSelection = []

let opponent = turn.opposite
if allLegalMoves(for: opponent).isEmpty {
winner = turn
return
}
turn = opponent
}

var pieceCount: (white: Int, black: Int) {
var w = 0, b = 0
for (_, p) in board {
if p.color == .white { w += 1 } else { b += 1 }
}
return (w, b)
}
}

// MARK: - Simple AI

extension CheckersEngine {
func botMove(for color: PieceColor) -> Move? {
let moves = allLegalMoves(for: color)
guard !moves.isEmpty else { return nil }

if let bestCapture = moves.filter({ $0.isCapture }).max(by: { $0.captured.count < $1.captured.count }) {
return bestCapture
}

var best = moves[0]
var bestScore = Int.min
for move in moves {
let score = evaluate(after: move, for: color)
if score > bestScore {
bestScore = score
best = move
}
}
return best
}

private func evaluate(after move: Move, for color: PieceColor) -> Int {
var simulated = board
guard var piece = simulated[move.path.first!] else { return 0 }
simulated[move.path.first!] = nil
for sq in move.captured { simulated[sq] = nil }
if move.promotesToKing { piece.kind = .king }
simulated[move.path.last!] = piece

var score = Int.random(in: 0...3)
for (sq, p) in simulated {
let value = (p.kind == .king ? 5 : 3)
score += (p.color == color ? value : -value)
if p.color == color, p.kind == .man {
let advancement = color == .white ? (7 - sq.row) : sq.row
score += advancement / 2
}
}
return score
}
}
