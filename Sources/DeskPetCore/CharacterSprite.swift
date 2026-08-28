import Foundation

/// 파라미터(Pose)로부터 캐릭터 픽셀아트를 그린다.
/// 프레임 이미지를 일일이 손으로 찍지 않고 자세 값만 바꿔서 모든 애니메이션을 만든다.
public enum CharacterSprite {

    // 스프라이트 캔버스 규격
    public static let canvasWidth = 64
    public static let canvasHeight = 48

    // 머리 (메인 캔버스 기준 중심)
    static let headCenterX = 32
    static let headCenterY = 17

    // 머리 서브 캔버스 (로컬 좌표)
    static let headW = 34, headH = 32
    static let hcx = 17, hcy = 15
    static let headRX = 12, headRY = 11

    // 몸통 서브 캔버스
    static let bodyW = 36, bodyH = 24
    static let bcx = 18

    public static func render(_ pose: Pose) -> PixelCanvas {
        var c = PixelCanvas(width: canvasWidth, height: canvasHeight)

        if pose.showDesk { drawDesk(&c) }
        var body = PixelCanvas(width: bodyW, height: bodyH)
        drawBody(&body, pose: pose)
        c.blit(body, dx: headCenterX - bcx, dy: 26 + pose.bodyOffsetY)

        var head = PixelCanvas(width: headW, height: headH)
        drawHead(&head, pose: pose)
        c.blit(head,
               dx: headCenterX - hcx,
               dy: headCenterY - hcy + pose.headOffsetY,
               shearPerRow: pose.headShear,
               pivotY: hcy + headRY)

        if pose.showDesk { drawKeyboard(&c, pose: pose) }
        drawArms(&c, pose: pose)
        drawCup(&c, pose: pose)
        if pose.sleepZ > 0 { drawSleepZ(&c, level: pose.sleepZ) }
        if pose.sweat { drawSweat(&c, pose: pose) }
        if pose.steam { drawSteam(&c, pose: pose) }
        return c
    }

    // MARK: - 머리

    static func drawHead(_ c: inout PixelCanvas, pose: Pose) {
        // 귀
        for (ex, dir) in [(hcx - headRX - 1, -1), (hcx + headRX + 1, 1)] {
            c.fillRect(x: ex, y: hcy + 1, w: 2, h: 3, .outline)
            c.fillRect(x: ex + (dir < 0 ? 1 : 0), y: hcy + 2, w: 1, h: 2, .skin)
        }
        // 얼굴
        c.fillEllipse(cx: hcx, cy: hcy, rx: headRX + 1, ry: headRY + 1, .outline)
        c.fillEllipse(cx: hcx, cy: hcy, rx: headRX, ry: headRY, .skin)
        // 오른쪽 아래 음영
        for y in (hcy - 2)...(hcy + headRY) {
            var rightMost = -1
            for x in hcx...(hcx + headRX + 1) where c[x, y] == PixelColor.skin.rawValue { rightMost = x }
            if rightMost > 0 { c.shade(rightMost, y, .skinShade) }
        }
        for x in (hcx - 5)...(hcx + 5) {
            var lowest = -1
            for y in hcy...(hcy + headRY + 1) where c[x, y] == PixelColor.skin.rawValue { lowest = y }
            if lowest > 0 { c.shade(x, lowest, .skinShade) }
        }

        drawHair(&c)
        drawBrows(&c, pose: pose)
        drawGlassesAndEyes(&c, pose: pose)
        drawFace(&c, pose: pose)
    }

    /// 검은 가르마 머리: 가르마 오른쪽은 짧고, 왼쪽으로 길게 쓸어넘긴 앞머리.
    /// 머리카락은 두상보다 한 겹 크게 그려서 숱이 있어 보이게 한다.
    static func drawHair(_ c: inout PixelCanvas) {
        let partX = hcx + 4

        /// x 위치에서 머리카락이 내려오는 아래쪽 경계.
        func bangLine(_ x: Int) -> Double {
            let t = Double(x - partX)
            var bang: Double = t <= 0
                ? Double(hcy) - 9 + (-t) * 0.15      // 왼쪽으로 갈수록 앞머리가 내려온다
                : Double(hcy) - 9 - t * 0.22         // 가르마 오른쪽도 너무 파이지 않게
            bang = min(bang, Double(hcy) - 7)         // 이마와 눈썹은 가리지 않는다
            let edge = abs(x - hcx)
            if edge >= 9 {                            // 옆머리는 귀 옆까지 풍성하게
                bang = max(bang, min(Double(hcy) + 2, Double(hcy) - 12 + Double(edge) * 1.3))
            }
            return bang
        }

        // 1) 머리카락 외곽선 (두상보다 크게 = 볼륨)
        for y in 0..<c.height {
            for x in 0..<c.width where Double(y) <= bangLine(x) + 1 {
                if c.ellipseContains(cx: hcx, cy: hcy - 2, rx: headRX + 2, ry: headRY + 2, x: x, y: y) {
                    c.plot(x, y, .outline)
                }
            }
        }
        // 2) 머리카락 본체
        for y in 0..<c.height {
            for x in 0..<c.width where Double(y) <= bangLine(x) {
                if c.ellipseContains(cx: hcx, cy: hcy - 2, rx: headRX + 1, ry: headRY + 1, x: x, y: y) {
                    c.plot(x, y, .hair)
                }
            }
        }

        // 머릿결 하이라이트 (가르마에서 왼쪽 위로 흐르는 결)
        for i in 0..<9 {
            let x = partX - 1 - i
            let y = hcy - 12 + (i * i) / 9
            if c[x, y] == PixelColor.hair.rawValue { c.plot(x, y, .hairHighlight) }
            if i % 3 == 1, c[x, y + 1] == PixelColor.hair.rawValue { c.plot(x, y + 1, .hairHighlight) }
        }
        // 가르마 선
        for i in 0..<3 where c[partX + i, hcy - 12 + i] == PixelColor.hair.rawValue {
            c.plot(partX + i, hcy - 12 + i, .hairHighlight)
        }
    }

    static func drawBrows(_ c: inout PixelCanvas, pose: Pose) {
        let y = max(hcy - 5, hcy - 4 - pose.browRaise)
        // 왼쪽 눈썹 (바깥쪽 끝이 살짝 내려간 순한 눈썹)
        for i in 0..<7 {
            let x = hcx - 10 + i
            c.plot(x, y + (i < 2 ? 1 : 0), .brow)
        }
        for i in 0..<7 {
            let x = hcx + 4 + i
            c.plot(x, y + (i > 4 ? 1 : 0), .brow)
        }
    }

    static func drawGlassesAndEyes(_ c: inout PixelCanvas, pose: Pose) {
        let ox = pose.glassesOffsetX
        let oy = pose.glassesOffsetY
        let lensTop = hcy - 1 + oy
        let lensH = 7
        let leftX = hcx - 11 + ox
        let rightX = hcx + 3 + ox
        let lensW = 9

        // 눈은 안경 알 안에 그린다
        drawEye(&c, centerX: hcx - 7 + ox, top: lensTop + pose.glassesTilt, pose: pose)
        drawEye(&c, centerX: hcx + 7 + ox, top: lensTop, pose: pose)

        drawLensFrame(&c, x: leftX, y: lensTop + pose.glassesTilt, w: lensW, h: lensH, glare: pose.glassesGlare)
        drawLensFrame(&c, x: rightX, y: lensTop, w: lensW, h: lensH, glare: pose.glassesGlare)

        // 콧대(브릿지)
        let bridgeY = lensTop + 2
        c.hLine(leftX + lensW, rightX - 1, bridgeY, .glassFrame)
        // 안경 다리
        c.hLine(leftX - 3, leftX - 1, lensTop + 2 + pose.glassesTilt, .glassFrame)
        c.hLine(rightX + lensW, rightX + lensW + 2, lensTop + 2, .glassFrame)
    }

    static func drawLensFrame(_ c: inout PixelCanvas, x: Int, y: Int, w: Int, h: Int, glare: Bool) {
        c.hLine(x, x + w - 1, y, .glassFrame)
        c.hLine(x, x + w - 1, y + h - 1, .glassFrame)
        c.vLine(x, y, y + h - 1, .glassFrame)
        c.vLine(x + w - 1, y, y + h - 1, .glassFrame)
        if glare {
            // 안경 알 반사 (대각선 두 줄)
            c.plot(x + 2, y + 2, .lensGlare)
            c.plot(x + 3, y + 1, .lensGlare)
            c.plot(x + 2, y + 3, .lens)
        }
    }

    static func drawEye(_ c: inout PixelCanvas, centerX: Int, top: Int, pose: Pose) {
        let eyeTop = top + 1
        let rows = Int((4.0 * pose.eyeOpen).rounded())
        if rows <= 0 {
            // 감은 눈: 아래로 볼록한 곡선
            c.hLine(centerX - 1, centerX + 1, eyeTop + 3, .pupil)
            c.plot(centerX - 2, eyeTop + 2, .pupil)
            c.plot(centerX + 2, eyeTop + 2, .pupil)
            return
        }
        let h = min(4, rows)
        let whiteTop = eyeTop + (4 - h)
        c.fillRect(x: centerX - 2, y: whiteTop, w: 5, h: h, .eyeWhite)
        let px = centerX - 1 + max(-1, min(1, pose.gazeX))
        let ph = min(3, h)
        let py = whiteTop + max(0, min(h - ph, 1 + pose.gazeY))
        c.fillRect(x: px, y: py, w: 2, h: ph, .pupil)
        if ph >= 3 { c.plot(px + 1, py, .eyeWhite) }   // 눈동자 하이라이트
        if h < 4 { c.hLine(centerX - 2, centerX + 2, whiteTop - 1, .pupil) }  // 반쯤 감긴 눈꺼풀
    }

    static func drawFace(_ c: inout PixelCanvas, pose: Pose) {
        // 코
        c.plot(hcx, hcy + 6, .skinLine)
        c.plot(hcx, hcy + 7, .skinLine)

        let my = hcy + 9
        switch pose.mouth {
        case .neutral:
            c.hLine(hcx - 1, hcx + 1, my, .skinLine)
        case .smile:
            c.hLine(hcx - 1, hcx + 1, my + 1, .mouth)
            c.plot(hcx - 2, my, .mouth)
            c.plot(hcx + 2, my, .mouth)
        case .open:
            c.roundedRect(x: hcx - 1, y: my - 1, w: 4, h: 3, .mouth)
        case .wavy:
            c.plot(hcx - 3, my + 1, .mouth)
            c.plot(hcx - 2, my, .mouth)
            c.plot(hcx - 1, my + 1, .mouth)
            c.plot(hcx, my, .mouth)
            c.plot(hcx + 1, my + 1, .mouth)
            c.plot(hcx + 2, my, .mouth)
        case .sip:
            c.fillRect(x: hcx - 1, y: my, w: 3, h: 2, .mouth)
        case .yawn:
            c.roundedRect(x: hcx - 1, y: my - 1, w: 4, h: 5, .mouth)
        }

        if pose.blush {
            c.fillRect(x: hcx - 12, y: hcy + 4, w: 3, h: 2, .blush)
            c.fillRect(x: hcx + 10, y: hcy + 4, w: 3, h: 2, .blush)
        }
    }

    // MARK: - 몸통

    static func drawBody(_ c: inout PixelCanvas, pose: Pose) {
        // 목
        c.fillRect(x: bcx - 3, y: 0, w: 6, h: 6, .outline)
        c.fillRect(x: bcx - 2, y: 0, w: 4, h: 5, .skin)
        c.fillRect(x: bcx - 2, y: 4, w: 4, h: 1, .skinShade)

        switch pose.outfit {
        case .checkShirt: drawCheckShirt(&c)
        case .orangePuffer: drawPuffer(&c)
        case .kixlabTee: drawKixlabTee(&c)
        case .lgUniform: drawLGUniform(&c)
        }
    }

    /// 파란 체크 셔츠
    static func drawCheckShirt(_ c: inout PixelCanvas) {
        c.fillEllipse(cx: bcx, cy: 10, rx: 10, ry: 6, .outline)
        c.roundedRect(x: bcx - 10, y: 9, w: 20, h: 13, .outline)
        c.fillEllipse(cx: bcx, cy: 10, rx: 9, ry: 5, .shirt)
        c.roundedRect(x: bcx - 9, y: 9, w: 18, h: 11, .shirt)

        // 체크 무늬
        for y in 5..<22 {
            for x in (bcx - 11)...(bcx + 11) {
                guard c[x, y] == PixelColor.shirt.rawValue else { continue }
                let v = (x - bcx + 20) % 5 == 0
                let h = (y + 1) % 5 == 0
                if v && h { c.shade(x, y, .shirtCross) }
                else if v || h { c.shade(x, y, .shirtCheck) }
            }
        }

        // 카라 + 단추선
        c.plot(bcx - 3, 5, .collar); c.plot(bcx - 2, 6, .collar); c.plot(bcx - 2, 5, .collar)
        c.plot(bcx + 3, 5, .collar); c.plot(bcx + 2, 6, .collar); c.plot(bcx + 2, 5, .collar)
        c.plot(bcx - 1, 6, .collar); c.plot(bcx, 6, .collar); c.plot(bcx + 1, 6, .collar)
        for y in stride(from: 8, to: 21, by: 1) { c.shade(bcx, y, .collar) }
    }

    /// I ♥ KIXLAB 이 적힌 흰 티셔츠.
    /// 양팔이 가슴 양쪽을 가리므로, 팔 사이 빈 공간(가운데 11픽셀)에 세 줄로 나눠 찍는다.
    static func drawKixlabTee(_ c: inout PixelCanvas) {
        c.fillEllipse(cx: bcx, cy: 10, rx: 11, ry: 6, .outline)
        c.roundedRect(x: bcx - 11, y: 9, w: 23, h: 15, .outline)
        c.fillEllipse(cx: bcx, cy: 10, rx: 10, ry: 5, .tee)
        c.roundedRect(x: bcx - 10, y: 9, w: 21, h: 13, .tee)

        // 라운드넥
        c.fillEllipse(cx: bcx, cy: 4, rx: 4, ry: 2, .outline)
        c.fillEllipse(cx: bcx, cy: 4, rx: 3, ry: 1, .teeShade)
        // 옆구리 음영과 밑단
        for y in 6...21 {
            c.shade(bcx - 10, y, .teeShade)
            c.shade(bcx + 10, y, .teeShade)
        }
        for x in (bcx - 9)...(bcx + 9) { c.shade(x, 21, .teeShade) }

        // 프린트: I ♥ / KIX / LAB
        let iWidth = MicroFont.glyphWidth("i")
        let heartWidth = MicroFont.glyphWidth("♥")
        let topStart = bcx - (iWidth + 2 + heartWidth) / 2
        MicroFont.draw("i", into: &c, x: topStart, y: 6, color: .teeInk)
        MicroFont.draw("♥", into: &c, x: topStart + iWidth + 2, y: 6, color: .cupHeart)
        MicroFont.drawCentered("KIX", into: &c, centerX: bcx, y: 11, color: .teeInk)
        MicroFont.drawCentered("LAB", into: &c, centerX: bcx, y: 17, color: .teeInk)
    }

    /// LG 트윈스 홈 유니폼 (흰 바탕 + 검은 핀스트라이프 + 빨간 글자 + 어깨 검은 띠).
    /// 가슴 폭이 좁아 LG / TWI / NS 세 줄로 나눠 찍는다.
    static func drawLGUniform(_ c: inout PixelCanvas) {
        c.fillEllipse(cx: bcx, cy: 10, rx: 11, ry: 6, .outline)
        c.roundedRect(x: bcx - 11, y: 9, w: 23, h: 15, .outline)
        c.fillEllipse(cx: bcx, cy: 10, rx: 10, ry: 5, .tee)
        c.roundedRect(x: bcx - 10, y: 9, w: 21, h: 13, .tee)

        // 세로 핀스트라이프 (가운데 글자를 피해 2픽셀 어긋나게 배치)
        for y in 4...21 {
            for x in stride(from: bcx - 10, through: bcx + 10, by: 4) {
                c.shade(x, y, .pinstripe)
            }
        }

        // 어깨를 두르는 검은 띠 (바깥으로 갈수록 두껍게)
        for x in (bcx - 11)...(bcx + 11) where abs(x - bcx) > 3 {
            c.shade(x, 4, .uniformBlack)
            if abs(x - bcx) > 8 { c.shade(x, 5, .uniformBlack) }
        }

        // 목 트임(붉은 테두리)
        c.fillEllipse(cx: bcx, cy: 4, rx: 4, ry: 2, .outline)
        c.fillEllipse(cx: bcx, cy: 4, rx: 3, ry: 1, .uniformRed)

        // 옆구리 음영과 밑단
        for y in 7...21 {
            c.shade(bcx - 10, y, .teeShade)
            c.shade(bcx + 10, y, .teeShade)
        }
        for x in (bcx - 9)...(bcx + 9) { c.shade(x, 21, .teeShade) }

        // 가슴 로고: LG / TWI / NS
        MicroFont.drawCentered("lg", into: &c, centerX: bcx, y: 6, color: .uniformRed)
        MicroFont.drawCentered("TWI", into: &c, centerX: bcx, y: 11, color: .uniformRed)
        MicroFont.drawCentered("NS", into: &c, centerX: bcx, y: 17, color: .uniformRed)
    }

    /// 주황 패딩(누빔 점퍼) — 체크 셔츠보다 조금 더 통통하다.
    static func drawPuffer(_ c: inout PixelCanvas) {
        c.fillEllipse(cx: bcx, cy: 10, rx: 11, ry: 6, .outline)
        c.roundedRect(x: bcx - 11, y: 9, w: 22, h: 13, .outline)
        c.fillEllipse(cx: bcx, cy: 10, rx: 10, ry: 5, .puffer)
        c.roundedRect(x: bcx - 10, y: 9, w: 20, h: 11, .puffer)

        // 누빔 선: 가로로 부푼 칸을 나눈다
        for seamY in [8, 12, 16, 20] {
            for x in (bcx - 11)...(bcx + 11) where c[x, seamY] == PixelColor.puffer.rawValue {
                c.shade(x, seamY, .pufferSeam)
            }
            // 누빔 바로 위는 부푼 느낌의 밝은 면, 아래는 그림자
            for x in (bcx - 11)...(bcx + 11) {
                if c[x, seamY - 1] == PixelColor.puffer.rawValue { c.shade(x, seamY - 1, .pufferShade) }
                if c[x, seamY + 1] == PixelColor.puffer.rawValue { c.shade(x, seamY + 1, .pufferHigh) }
            }
        }
        // 양옆 음영
        for y in 6..<22 {
            for x in [bcx - 10, bcx + 10] where c[x, y] == PixelColor.puffer.rawValue {
                c.shade(x, y, .pufferShade)
            }
        }

        // 목을 감싸는 부푼 카라
        c.fillEllipse(cx: bcx, cy: 6, rx: 7, ry: 3, .outline)
        c.fillEllipse(cx: bcx, cy: 6, rx: 6, ry: 2, .pufferHigh)
        c.hLine(bcx - 4, bcx + 4, 7, .pufferShade)

        // 가운데 지퍼
        for y in 6..<22 where c[bcx, y] != 0 && c[bcx, y] != PixelColor.outline.rawValue {
            c.plot(bcx, y, .zipper)
            c.shade(bcx - 1, y, .pufferSeam)
            c.shade(bcx + 1, y, .pufferSeam)
        }
        c.plot(bcx, 8, .pufferSeam)   // 지퍼 손잡이
    }

    // MARK: - 팔과 손

    static func drawArms(_ c: inout PixelCanvas, pose: Pose) {
        let shoulderL = (x: 22, y: 33 + pose.bodyOffsetY)
        let shoulderR = (x: 42, y: 33 + pose.bodyOffsetY)
        let wristL: (x: Int, y: Int)
        let wristR: (x: Int, y: Int)
        if pose.handsOnKeyboard {
            wristL = (27, 39 - pose.leftHandLift)
            wristR = (38, 39 - pose.rightHandLift)
        } else if pose.cup == .atMouth || pose.cup == .raised {
            wristL = (20, 41)
            wristR = pose.cup == .atMouth ? (41, 31) : (43, 36)
        } else {
            wristL = (20, 41 - pose.leftHandLift)
            wristR = (44, 41 - pose.rightHandLift)
        }

        let finalL = pose.leftHandOverride.map { (x: $0.x, y: $0.y) } ?? wristL
        let finalR = pose.rightHandOverride.map { (x: $0.x, y: $0.y) } ?? wristR
        drawLimb(&c, from: shoulderL, to: finalL, outfit: pose.outfit)
        drawLimb(&c, from: shoulderR, to: finalR, outfit: pose.outfit)
    }

    static func drawLimb(_ c: inout PixelCanvas, from: (x: Int, y: Int), to: (x: Int, y: Int),
                         outfit: Outfit = .checkShirt) {
        let sleeveColor: PixelColor
        let sleeveDetail: PixelColor
        let sleeveLength: Double     // 반팔은 짧게
        switch outfit {
        case .orangePuffer: sleeveColor = .puffer; sleeveDetail = .pufferSeam; sleeveLength = 0.6
        case .checkShirt:   sleeveColor = .shirt;  sleeveDetail = .shirtCheck; sleeveLength = 0.6
        case .kixlabTee:    sleeveColor = .tee;    sleeveDetail = .teeShade;   sleeveLength = 0.35
        case .lgUniform:    sleeveColor = .tee;    sleeveDetail = .pinstripe;  sleeveLength = 0.4
        }
        let steps = max(abs(to.x - from.x), abs(to.y - from.y))
        guard steps > 0 else { return }
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = Int((Double(from.x) + Double(to.x - from.x) * t).rounded())
            let y = Int((Double(from.y) + Double(to.y - from.y) * t).rounded())
            c.fillEllipse(cx: x, cy: y, rx: 3, ry: 3, .outline)
        }
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = Int((Double(from.x) + Double(to.x - from.x) * t).rounded())
            let y = Int((Double(from.y) + Double(to.y - from.y) * t).rounded())
            let sleeve = t < sleeveLength
            // 유니폼은 소매 끝에 검은 띠가 들어간다
            let onSleeveBand = outfit == .lgUniform && t > sleeveLength * 0.7 && t < sleeveLength * 0.95
            c.fillEllipse(cx: x, cy: y, rx: 2, ry: 2,
                          sleeve ? (onSleeveBand ? .uniformBlack : sleeveColor) : .skin)
            if sleeve, !onSleeveBand, (x + y) % 5 == 0 { c.shade(x, y, sleeveDetail) }
        }
        // 손
        c.fillEllipse(cx: to.x, cy: to.y, rx: 3, ry: 3, .outline)
        c.fillEllipse(cx: to.x, cy: to.y, rx: 2, ry: 2, .skin)
        c.plot(to.x - 1, to.y + 2, .skinShade)
        c.plot(to.x + 1, to.y + 2, .skinShade)
    }

    // MARK: - 책상 / 키보드 / 컵

    static func drawDesk(_ c: inout PixelCanvas) {
        c.fillRect(x: 0, y: 43, w: canvasWidth, h: 1, .outline)
        c.fillRect(x: 0, y: 44, w: canvasWidth, h: 1, .deskLight)
        c.fillRect(x: 0, y: 45, w: canvasWidth, h: 3, .deskDark)
    }

    static func drawKeyboard(_ c: inout PixelCanvas, pose: Pose) {
        let top = 38 + pose.keyboardPress
        c.roundedRect(x: 14, y: top, w: 36, h: 6, .outline)
        c.roundedRect(x: 15, y: top + 1, w: 34, h: 4, .keyBody)
        for row in 0..<2 {
            for col in 0..<10 {
                let idx = row * 10 + col
                let pressed = (pose.pressedKey.map { $0 % 20 } == idx)
                let x = 16 + col * 3
                let y = top + 1 + row * 2 + (pressed ? 1 : 0)
                c.fillRect(x: x, y: y, w: 2, h: 1, pressed ? .keyShadow : .keyCap)
            }
        }
    }

    static func drawCup(_ c: inout PixelCanvas, pose: Pose) {
        let origin: (x: Int, y: Int)
        switch pose.cup {
        case .hidden: return
        case .onDesk: origin = (48, 35)
        case .raised: origin = (38, 32)
        case .atMouth: origin = (35, 26)
        }
        let x = origin.x, y = origin.y
        c.fillRect(x: x, y: y, w: 7, h: 7, .outline)
        c.fillRect(x: x + 1, y: y + 1, w: 5, h: 5, .cupBody)
        c.fillRect(x: x + 1, y: y + 5, w: 5, h: 1, .cupShade)
        // 손잡이
        c.plot(x + 7, y + 2, .outline)
        c.plot(x + 7, y + 3, .outline)
        // 컵에 그려진 작은 하트
        c.plot(x + 2, y + 2, .cupHeart)
        c.plot(x + 4, y + 2, .cupHeart)
        c.fillRect(x: x + 2, y: y + 3, w: 3, h: 1, .cupHeart)
        c.plot(x + 3, y + 4, .cupHeart)
    }

    static func drawSleepZ(_ c: inout PixelCanvas, level: Int) {
        let spots = [(46, 10, 3), (50, 6, 3), (54, 2, 3)]
        for i in 0..<min(level, spots.count) {
            let (x, y, s) = spots[i]
            c.hLine(x, x + s - 1, y, .zzz)
            c.hLine(x, x + s - 1, y + s - 1, .zzz)
            for k in 0..<s { c.plot(x + s - 1 - k, y + k, .zzz) }
        }
    }

    static func drawSweat(_ c: inout PixelCanvas, pose: Pose) {
        let x = 46, y = 8
        c.plot(x + 1, y, .zzz)
        c.fillEllipse(cx: x + 1, cy: y + 3, rx: 1, ry: 2, .zzz)
        c.plot(x + 1, y + 2, .steam)
    }

    static func drawSteam(_ c: inout PixelCanvas, pose: Pose) {
        guard pose.cup != .hidden else { return }
        let base: (Int, Int) = pose.cup == .onDesk ? (50, 32) : (38, pose.cup == .atMouth ? 20 : 26)
        for i in 0..<3 {
            c.plot(base.0 + (i % 2), base.1 - i * 2, .steam)
        }
    }
}

public extension CharacterSprite {
    /// 머리 중심 좌표(외부에서 시선 계산에 사용).
    static var headCenterXValue: Int { headCenterX }
    static var headCenterYValue: Int { headCenterY }
}
