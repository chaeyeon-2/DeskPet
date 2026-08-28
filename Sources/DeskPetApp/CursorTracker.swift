import AppKit

/// 커서 위치는 권한 없이 읽을 수 있는 NSEvent.mouseLocation 만 사용한다.
enum CursorTracker {
    static var location: CGPoint { NSEvent.mouseLocation }
}
