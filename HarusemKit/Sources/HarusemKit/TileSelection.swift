/// 타일 → 연산자 → 타일 입력을 해석하는 선택 상태 머신 (NYT Digits 방식).
/// UI 프레임워크를 모르는 순수 로직. 병합 실행은 GameState에 위임한다.
public struct TileSelection: Equatable, Sendable {
    public private(set) var lhsID: Int?
    public private(set) var op: Op?

    public enum TapResult: Equatable, Sendable {
        case selectionChanged
        case merged(GameState.Tile)
        /// 결과가 양의 정수가 아니어서 차단됨 (선택은 유지 → UI에서 흔들기 등 피드백).
        case rejected
        case ignored
    }

    public init() {}

    public mutating func clear() {
        lhsID = nil
        op = nil
    }

    public mutating func tapTile(_ id: Int, state: inout GameState) -> TapResult {
        guard state.tiles.contains(where: { $0.id == id }) else { return .ignored }

        // 같은 타일 다시 탭 → 선택 해제
        if lhsID == id {
            clear()
            return .selectionChanged
        }
        // 첫 선택이거나 연산자 없이 다른 타일 탭 → lhs 교체
        guard let lhsID, let op else {
            self.lhsID = id
            self.op = nil
            return .selectionChanged
        }
        // lhs + 연산자 + rhs → 병합 시도
        guard state.canMerge(lhsID: lhsID, op: op, rhsID: id) else { return .rejected }
        let merged = try! state.merge(lhsID: lhsID, op: op, rhsID: id)  // canMerge 확인 후라 실패 불가
        self.lhsID = merged.id  // 결과 타일을 선택 유지 → 연쇄 계산
        self.op = nil
        return .merged(merged)
    }

    public mutating func tapOp(_ tapped: Op) -> TapResult {
        guard lhsID != nil else { return .ignored }
        op = (op == tapped) ? nil : tapped  // 같은 연산자 다시 탭 → 해제
        return .selectionChanged
    }
}
