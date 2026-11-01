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
    var row: Int // 0-indexed, row 0 = Black's back rank
    var col: Int // 0-indexed

    var isDark: Bool { (row + col) % 2 == 1 }
}

struct Move: Codable {
    var path: [Square] // full sequence of squares visited, path[0] = start
    var captured: [Square] // squares of captured pieces, in order
    var promotesToKing: Bool

    var isCapture: Bool { !captured.isEmpty }
}

/// The four rule variants this engine supports. Each variant is fully
/// described by the handful of properties below; `CheckersEngine` reads
/// them instead of hardcoding board size, king movement, capture
/// direction or win condition.
enum CheckersVariant: String, Codable, CaseIterable, Equatable {
    case russian        // Русские шашки — 8x8, flying kings, omni-directional capture
    case giveaway        // Поддавки — identical rules to russian, reversed win condition
    case international   // Международные — 10x10, 20 pieces/side, mandatory max-capture
    case english         // Английские (American checkers) — 8x8, forward-only men, non-flying kings

    /// Board is boardSize x boardSize.
    var boardSize: Int {
        self == .international ? 10 : 8
    }

    /// Number of back rows (per side) filled with men at the start.
    var pieceRows: Int {
        self == .international ? 4 : 3
    }

    /// Kings slide any distance along an open diagonal (true) or move/capture
    /// only one square (false, English checkers).
    var flyingKings: Bool {
        self != .english
    }

    /// Men may capture backward as well as forward (true for russian/
    /// giveaway/international). English men capture forward only.
    var menCaptureBackward: Bool {
        self != .english
    }

    /// International draughts: when several different capturing lines are
    /// available, only the one(s) taking the maximum number of pieces are legal.
    var maxCaptureRequired: Bool {
        self == .international
    }

    /// Giveaway (Поддавки): the normal "no legal move = you lose" condition
    /// is reversed — having no legal move (including having no pieces left)
    /// makes that player the WINNER.
    var reversedWin: Bool {
        self == .giveaway
    }
}

/// Draughts engine generalized across 4 rule variants: Russian, Giveaway
/// (Поддавки), International (10x10) and English (American checkers).
/// Board size, piece rows, king flight, men's capture directions, the
/// "must capture the most" rule and the win condition are all driven by
/// `variant` rather than hardcoded.
final class CheckersEngine: ObservableObject {
    let variant: CheckersVariant

    @Published var board: [Square: Piece] = [:]
    @Published var turn: PieceColor = .white
    @Published var winner: PieceColor? = nil
    @Published var lastMove: Move? = nil
    @Published var selectedSquare: Square? = nil
    @Published var legalMovesForSelection: [Move] = []

    var whiteCaptured = 0
    var blackCaptured = 0

    var boardSize: Int { variant.boardSize }
    var pieceRows: Int { variant.pieceRows }

    init(variant: CheckersVariant = .russian) {
        self.variant = variant
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

        for row in 0..<pieceRows {
            for col in 0..<boardSize where Square(row: row, col: col).isDark {
                board[Square(row: row, col: col)] = Piece(color: .black)
            }
        }
        for row in (boardSize - pieceRows)..<boardSize {
            for col in 0..<boardSize where Square(row: row, col: col).isDark {
                board[Square(row: row, col: col)] = Piece(color: .white)
            }
        }
    }

    func tap(_ sq: Square) {
        guard winner == nil else { return }
        if selectedSquare != nil {
            if let mv = legalMovesForSelection.first(where: { $0.path.last == sq }) {
                apply(mv)
                return
            }
        }
        guard let piece = board[sq], piece.color == turn else {
            selectedSquare = nil
            legalMovesForSelection = []
            return
        }
        selectedSquare = sq
        legalMovesForSelection = moves(for: turn).filter { $0.path.first == sq }
    }

    func apply(_ move: Move) {
        guard let start = move.path.first, var piece = board[start] else { return }
        board[start] = nil
        for cap in move.captured { board[cap] = nil }
        if move.promotesToKing { piece.kind = .king }
        board[move.path.last!] = piece
        if move.isCapture {
            if piece.color == .white { blackCaptured += move.captured.count } else { whiteCaptured += move.captured.count }
        }
        lastMove = move
        selectedSquare = nil
        legalMovesForSelection = []
        checkWinner()
        if winner == nil {
            turn = turn.opposite
        }
    }

    func botMove(for color: PieceColor) -> Move? {
        let all = moves(for: color)
        guard !all.isEmpty else { return nil }
        // prefer captures, then random
        let captures = all.filter { $0.isCapture }
        let pool = captures.isEmpty ? all : captures
        return pool.randomElement()
    }

    // MARK: - Move generation

    func moves(for color: PieceColor) -> [Move] {
        var all: [Move] = []
        for (sq, piece) in board where piece.color == color {
            all.append(contentsOf: movesForPiece(at: sq, piece: piece))
        }
        let captures = all.filter { $0.isCapture }
        if captures.isEmpty { return all }
        if variant.maxCaptureRequired, let maxCount = captures.map({ $0.captured.count }).max() {
            return captures.filter { $0.captured.count == maxCount }
        }
        return captures
    }

    private func movesForPiece(at sq: Square, piece: Piece) -> [Move] {
        var result: [Move] = []
        let captureSeqs = captureSequences(from: sq, piece: piece, board: board, visited: [])
        if !captureSeqs.isEmpty {
            return captureSeqs
        }
        if piece.kind == .man {
            let dirs = forwardDirections(for: piece.color)
            for (dr, dc) in dirs {
                let dest = Square(row: sq.row + dr, col: sq.col + dc)
                if isOnBoard(dest), board[dest] == nil {
                    let promotes = willPromote(dest, color: piece.color)
                    result.append(Move(path: [sq, dest], captured: [], promotesToKing: promotes))
                }
            }
        } else if variant.flyingKings {
            for (dr, dc) in allDirections {
                var step = 1
                while true {
                    let dest = Square(row: sq.row + dr * step, col: sq.col + dc * step)
                    guard isOnBoard(dest), board[dest] == nil else { break }
                    result.append(Move(path: [sq, dest], captured: [], promotesToKing: false))
                    step += 1
                }
            }
        } else {
            // Non-flying king (English checkers): one square, any direction.
            for (dr, dc) in allDirections {
                let dest = Square(row: sq.row + dr, col: sq.col + dc)
                if isOnBoard(dest), board[dest] == nil {
                    result.append(Move(path: [sq, dest], captured: [], promotesToKing: false))
                }
            }
        }
        return result
    }

    private func captureSequences(from sq: Square, piece: Piece, board: [Square: Piece], visited: Set<Square>) -> [Move] {
        var results: [Move] = []
        if piece.kind == .man {
            let dirs = variant.menCaptureBackward ? allDirections : forwardDirections(for: piece.color)
            for (dr, dc) in dirs {
                let mid = Square(row: sq.row + dr, col: sq.col + dc)
                let dest = Square(row: sq.row + 2 * dr, col: sq.col + 2 * dc)
                guard isOnBoard(dest) else { continue }
                guard let midPiece = board[mid], midPiece.color == piece.color.opposite else { continue }
                guard board[dest] == nil else { continue }
                var nextBoard = board
                nextBoard[sq] = nil
                nextBoard[mid] = nil
                let promotes = willPromote(dest, color: piece.color)
                var movedPiece = piece
                if promotes { movedPiece.kind = .king }
                nextBoard[dest] = movedPiece
                let further = captureSequences(from: dest, piece: movedPiece, board: nextBoard, visited: [])
                if further.isEmpty {
                    results.append(Move(path: [sq, dest], captured: [mid], promotesToKing: promotes))
                } else {
                    for f in further {
                        results.append(Move(path: [sq] + f.path.dropFirst(), captured: [mid] + f.captured, promotesToKing: f.promotesToKing))
                    }
                }
            }
        } else if variant.flyingKings {
            for (dr, dc) in allDirections {
                var step = 1
                var foundEnemy: Square? = nil
                while true {
                    let probe = Square(row: sq.row + dr * step, col: sq.col + dc * step)
                    guard isOnBoard(probe) else { break }
                    if let p = board[probe] {
                        if foundEnemy == nil, p.color == piece.color.opposite {
                            foundEnemy = probe
                            step += 1
                            continue
                        } else {
                            break
                        }
                    }
                    if let enemy = foundEnemy {
                        var nextBoard = board
                        nextBoard[sq] = nil
                        nextBoard[enemy] = nil
                        nextBoard[probe] = piece
                        let further = captureSequences(from: probe, piece: piece, board: nextBoard, visited: [])
                        if further.isEmpty {
                            results.append(Move(path: [sq, probe], captured: [enemy], promotesToKing: false))
                        } else {
                            for f in further {
                                results.append(Move(path: [sq] + f.path.dropFirst(), captured: [enemy] + f.captured, promotesToKing: f.promotesToKing))
                            }
                        }
                    }
                    step += 1
                }
            }
        } else {
            // Non-flying king (English checkers): one square capture, any direction.
            for (dr, dc) in allDirections {
                let mid = Square(row: sq.row + dr, col: sq.col + dc)
                let dest = Square(row: sq.row + 2 * dr, col: sq.col + 2 * dc)
                guard isOnBoard(dest) else { continue }
                guard let midPiece = board[mid], midPiece.color == piece.color.opposite else { continue }
                guard board[dest] == nil else { continue }
                var nextBoard = board
                nextBoard[sq] = nil
                nextBoard[mid] = nil
                nextBoard[dest] = piece
                let further = captureSequences(from: dest, piece: piece, board: nextBoard, visited: [])
                if further.isEmpty {
                    results.append(Move(path: [sq, dest], captured: [mid], promotesToKing: false))
                } else {
                    for f in further {
                        results.append(Move(path: [sq] + f.path.dropFirst(), captured: [mid] + f.captured, promotesToKing: f.promotesToKing))
                    }
                }
            }
        }
        return results
    }

    private func forwardDirections(for color: PieceColor) -> [(Int, Int)] {
        color == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)]
    }

    private let allDirections: [(Int, Int)] = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

    private func isOnBoard(_ sq: Square) -> Bool {
        sq.row >= 0 && sq.row < boardSize && sq.col >= 0 && sq.col < boardSize
    }

    private func willPromote(_ sq: Square, color: PieceColor) -> Bool {
        (color == .white && sq.row == 0) || (color == .black && sq.row == boardSize - 1)
    }

    /// Checks whether the player about to move (`turn.opposite`, i.e. the
    /// side that did NOT just move) has any legal move. If not, the game
    /// ends. Under normal rules the player who just moved (`turn`) wins
    /// because their opponent is stuck. Under Giveaway's reversed win
    /// condition, being stuck (which also covers having no pieces left,
    /// since `moves(for:)` over an empty set of own pieces is naturally
    /// empty) makes the STUCK player the winner instead.
    private func checkWinner() {
        let opponent = turn.opposite
        if moves(for: opponent).isEmpty {
            winner = variant.reversedWin ? opponent : turn
        }
    }

    var pieceCount: (white: Int, black: Int) {
        var w = 0, b = 0
        for (_, p) in board { if p.color == .white { w += 1 } else { b += 1 } }
        return (w, b)
    }
}
