import SwiftUI
import DeskPetCore

private let inkColor = Color(red: 0.17, green: 0.14, blue: 0.19)

struct PetView: View {
    @ObservedObject var model: PetViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Color.clear
                if let text = model.bubbleText {
                    SpeechBubbleView(text: text)
                        .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .bottom)))
                }
            }
            .frame(height: model.bubbleAreaHeight)
            .animation(.easeInOut(duration: 0.32), value: model.bubbleText)

            ZStack(alignment: .top) {
                Image(nsImage: model.image)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .colorMultiply(model.attentionAlert
                                   ? Color(red: 1, green: 0.18, blue: 0.18)
                                   : .white)
                    .shadow(color: model.attentionAlert ? .red.opacity(0.95) : .clear,
                            radius: model.attentionAlert ? 14 : 0)
                    // 평소에는 원본 픽셀 프레임만 표시한다. 경고 상태일 때만
                    // 붉은 글로우와 확대를 적용해 일반 애니메이션에 부담을 주지 않는다.
                    .scaleEffect(model.attentionAlert ? 1.06 : 1)
                    .offset(x: model.attentionAlert ? 2 : 0)

                if let time = model.focusTimeText {
                    FocusTimerBadge(time: time, paused: model.focusIsPaused,
                                    alerting: model.attentionAlert)
                        .padding(.top, 4)
                }
            }
            .frame(width: model.spriteSize.width, height: model.spriteSize.height)
        }
        .frame(width: model.windowSize.width, height: model.windowSize.height, alignment: .bottom)
        .animation(.easeInOut(duration: 0.18), value: model.attentionAlert)
    }
}

private struct FocusTimerBadge: View {
    let time: String
    let paused: Bool
    let alerting: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: paused ? "pause.fill" : "timer")
            Text(time).monospacedDigit()
        }
        .font(.system(size: 12, weight: .heavy, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(alerting ? Color(red: 0.82, green: 0.03, blue: 0.06) : Color(red: 0.12, green: 0.16, blue: 0.24))
        )
        .overlay(Capsule().strokeBorder(alerting ? Color.red.opacity(0.95) : .white.opacity(0.35), lineWidth: 1.5))
        .shadow(color: alerting ? .red.opacity(0.9) : .black.opacity(0.22), radius: alerting ? 8 : 3, y: 2)
        .accessibilityLabel(paused ? "Focus timer paused" : "Focus timer")
    }
}

struct SpeechBubbleView: View {
    let text: String

    var body: some View {
        VStack(spacing: -1) {
            Text(text)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(inkColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(inkColor, lineWidth: 2)
                        )
                )
            BubbleTail()
                .frame(width: 14, height: 8)
        }
        .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
        .padding(.horizontal, 10)
        .padding(.bottom, 2)
    }
}

/// 말풍선 꼬리. 위쪽 선은 그리지 않아 몸통과 자연스럽게 이어진다.
private struct BubbleTail: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 14, y: 0))
                p.addLine(to: CGPoint(x: 5, y: 8))
                p.closeSubpath()
            }
            .fill(Color.white)
            Path { p in
                p.move(to: CGPoint(x: 13, y: 0))
                p.addLine(to: CGPoint(x: 5, y: 7))
                p.addLine(to: CGPoint(x: 1, y: 0))
            }
            .stroke(inkColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 14, height: 8)
    }
}
