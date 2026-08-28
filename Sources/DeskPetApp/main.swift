import AppKit
import DeskPetCore

// `DeskPet --export-sprites <폴더>` : 현재 픽셀아트를 PNG 로 뽑아낸다.
// (자산을 다른 그림으로 교체할 때 크기/프레임 수를 확인하는 용도)
let arguments = CommandLine.arguments
if let index = arguments.firstIndex(of: "--export-sprites") {
    let path = index + 1 < arguments.count ? arguments[index + 1] : "./Sprites"
    let scaleArg = arguments.firstIndex(of: "--scale").flatMap { i -> Int? in
        i + 1 < arguments.count ? Int(arguments[i + 1]) : nil
    }
    let directory = URL(fileURLWithPath: path)
    do {
        let files = try SpriteExport.exportAll(to: directory, scale: scaleArg ?? 4)
        print(L10n.t("\(files.count)개 파일을 저장했습니다: ", "Wrote \(files.count) files to ") + directory.path)
        exit(0)
    } catch {
        FileHandle.standardError.write(Data((L10n.t("스프라이트를 저장하지 못했습니다: ", "Sprite export failed: ") + "\(error)\n").utf8))
        exit(1)
    }
}

// `DeskPet --export-iconset <폴더>` : 앱 아이콘 원본(.iconset) 생성
if let index = arguments.firstIndex(of: "--export-iconset") {
    let path = index + 1 < arguments.count ? arguments[index + 1] : "./DeskPet.iconset"
    do {
        let files = try AppIcon.exportIconSet(to: URL(fileURLWithPath: path))
        print(L10n.t("아이콘 \(files.count)개를 만들었습니다: ", "Wrote \(files.count) icon files to ") + path)
        exit(0)
    } catch {
        FileHandle.standardError.write(Data((L10n.t("아이콘 생성 실패: ", "Icon export failed: ") + "\(error)\n").utf8))
        exit(1)
    }
}

// `DeskPet --diagnose <로그파일>` : 키 입력이 실제로 도달하는지 확인
if let index = arguments.firstIndex(of: "--diagnose") {
    let path = index + 1 < arguments.count ? arguments[index + 1] : "./deskpet-diagnose.txt"
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let diagnose = Diagnose(logURL: URL(fileURLWithPath: path))
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { diagnose.run() }
    app.run()
    exit(0)
}

// `DeskPet --selftest <폴더>` : 실제 창을 띄워 동작을 스스로 점검한다.
if let index = arguments.firstIndex(of: "--selftest") {
    let path = index + 1 < arguments.count ? arguments[index + 1] : "./selftest"
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let test = SelfTest(outputDirectory: URL(fileURLWithPath: path))
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { test.run() }
    app.run()
    exit(0)
}

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.setActivationPolicy(.accessory)
application.run()
