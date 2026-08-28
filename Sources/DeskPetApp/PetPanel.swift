import AppKit
import DeskPetCore

/// 테두리 없는 투명 창. 포커스를 빼앗지 않고 모든 Space 에서 보인다.
final class PetPanel: NSPanel {

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(size: CGSize) {
        super.init(contentRect: CGRect(origin: .zero, size: size),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false                 // 드래그는 직접 처리한다
        level = .floating                 // 다른 앱 위에 떠 있기
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        ignoresMouseEvents = false
    }
}

/// 캐릭터 픽셀 위에서만 마우스를 받고, 나머지 투명한 부분은 클릭이 그대로 통과한다.
final class PetContentView: NSView {

    var spriteFrame: CGRect = .zero
    var pixelScale: CGFloat = 3
    var isOpaquePixel: ((Int, Int) -> Bool)?
    var onDragBegin: (() -> Void)?
    var onDrag: ((CGSize) -> Void)?
    var onDragEnd: (() -> Void)?
    var onClick: ((Bool) -> Void)?        // Bool = 머리를 눌렀는지

    private var dragStartMouse: CGPoint?
    private var totalDrag: CGFloat = 0
    private var pressedOnHead = false

    override var isFlipped: Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        guard let canvasPoint = canvasCoordinate(for: local) else { return nil }
        guard isOpaquePixel?(canvasPoint.x, canvasPoint.y) == true else { return nil }
        return self
    }

    /// 뷰 좌표 → 스프라이트 픽셀 좌표(위가 0).
    private func canvasCoordinate(for point: CGPoint) -> (x: Int, y: Int)? {
        guard spriteFrame.contains(point), pixelScale > 0 else { return nil }
        let x = Int((point.x - spriteFrame.minX) / pixelScale)
        let y = Int((spriteFrame.maxY - point.y) / pixelScale)
        guard x >= 0, y >= 0, x < CharacterSprite.canvasWidth, y < CharacterSprite.canvasHeight else { return nil }
        return (x, y)
    }

    override func mouseDown(with event: NSEvent) {
        dragStartMouse = NSEvent.mouseLocation
        totalDrag = 0
        let local = convert(event.locationInWindow, from: nil)
        pressedOnHead = (canvasCoordinate(for: local)?.y ?? 99) <= 30
        onDragBegin?()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStartMouse else { return }
        let now = NSEvent.mouseLocation
        let delta = CGSize(width: now.x - start.x, height: now.y - start.y)
        totalDrag += abs(delta.width) + abs(delta.height)
        dragStartMouse = now
        onDrag?(delta)
    }

    override func mouseUp(with event: NSEvent) {
        defer { dragStartMouse = nil }
        if totalDrag < 3 {
            onClick?(pressedOnHead)
        } else {
            onDragEnd?()
        }
    }
}
