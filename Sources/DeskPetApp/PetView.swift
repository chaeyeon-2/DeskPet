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

            Image(nsImage: model.image)
                .resizable()
                .interpolation(.none)
                .antialiased(false)
                .frame(width: model.spriteSize.width, height: model.spriteSize.height)
        }
        .frame(width: model.windowSize.width, height: model.windowSize.height, alignment: .bottom)
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
