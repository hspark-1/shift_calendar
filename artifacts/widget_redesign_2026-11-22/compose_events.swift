// macOS AppKit으로 실제 SwiftUI 렌더 PNG를 검토판에 배치한다. 제품에는 포함하지 않는다.
import AppKit

let renders = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

struct Tile {
    let name: String
    let title: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

func compose(name: String, title: String, height: CGFloat, tiles: [Tile]) throws {
    let size = NSSize(width: 1260, height: height)
    let canvas = NSImage(size: size)
    canvas.lockFocus()
    NSColor(srgbRed: 0.94, green: 0.95, blue: 0.97, alpha: 1).setFill()
    NSRect(origin: .zero, size: size).fill()

    func label(_ text: String, x: CGFloat, y: CGFloat, font_size: CGFloat, bold: Bool = false) {
        (text as NSString).draw(in: NSRect(x: x, y: height - y - font_size * 1.6,
            width: 1180 - x, height: font_size * 1.6), withAttributes: [
                .font: NSFont.systemFont(ofSize: font_size, weight: bold ? .bold : .regular),
                .foregroundColor: NSColor(srgbRed: 0.12, green: 0.16, blue: 0.21, alpha: 1)
            ])
    }
    label(title, x: 40, y: 24, font_size: 34, bold: true)
    label("예시 데이터 · 실제 SwiftUI 렌더 · WidgetKit 시스템 합성/실기기 인수와 구분", x: 40, y: 82, font_size: 19)
    for tile in tiles {
        label(tile.title, x: tile.x, y: tile.y - 38, font_size: 21, bold: true)
        let url = renders.appendingPathComponent(tile.name + ".png")
        guard let image = NSImage(contentsOf: url) else { fatalError("누락된 렌더: \(url.path)") }
        let rect = NSRect(x: tile.x, y: height - tile.y - tile.height, width: tile.width, height: tile.height)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: rect, xRadius: 20, yRadius: 20).addClip()
        image.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()
    }
    canvas.unlockFocus()
    guard let tiff = canvas.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("PNG 변환 실패") }
    try png.write(to: output.appendingPathComponent(name + ".png"))
}

try compose(name: "events-overview", title: "근무 위젯에 일정 표시", height: 1120, tiles: [
    Tile(name: "0-small-light", title: "오늘 · 일정 건수", x: 40, y: 170, width: 300, height: 300),
    Tile(name: "1-small-light", title: "내일 · 일정 건수", x: 360, y: 170, width: 300, height: 300),
    Tile(name: "0-medium-light", title: "2주 · 일정이 있는 날에 점", x: 700, y: 170, width: 520, height: 243),
    Tile(name: "0-small-dark", title: "다크 모드", x: 40, y: 540, width: 300, height: 300),
    Tile(name: "1-small-dark", title: "내일", x: 360, y: 540, width: 300, height: 300),
    Tile(name: "0-medium-dark", title: "2주", x: 700, y: 540, width: 520, height: 243),
    Tile(name: "0-circular-vibrant", title: "잠금 · 유무", x: 40, y: 930, width: 110, height: 110),
    Tile(name: "0-rectangular-light", title: "잠금 · 건수", x: 200, y: 930, width: 320, height: 141),
    Tile(name: "0-inline-light", title: "잠금 · 한 줄", x: 590, y: 965, width: 620, height: 66)
])

try compose(name: "events-edge-cases", title: "일정 표시 · 작은 공간과 데이터 경계", height: 1240, tiles: [
    Tile(name: "0-small-narrow-large", title: "140pt · 큰 글자", x: 40, y: 170, width: 280, height: 280),
    Tile(name: "0-small-long-large", title: "긴 코드 · 큰 글자", x: 350, y: 170, width: 280, height: 280),
    Tile(name: "0-small-many-events-narrow-large", title: "많은 일정 · 99+", x: 660, y: 170, width: 280, height: 280),
    Tile(name: "0-small-missing", title: "근무 없이 일정만", x: 970, y: 170, width: 250, height: 250),
    Tile(name: "0-small-no-events", title: "일정 0건", x: 40, y: 550, width: 280, height: 280),
    Tile(name: "0-small-legacy", title: "구 캐시 · 일정 미확인", x: 350, y: 550, width: 280, height: 280),
    Tile(name: "0-small-logged-out", title: "로그아웃", x: 660, y: 550, width: 280, height: 280),
    Tile(name: "0-small-accented", title: "단색 모드 분기", x: 970, y: 550, width: 250, height: 250),
    Tile(name: "0-rectangular-narrow-large", title: "잠금 · 좁은 폭/큰 글자", x: 40, y: 950, width: 375, height: 160),
    Tile(name: "0-medium-large", title: "2주 · 큰 글자", x: 470, y: 915, width: 600, height: 280)
])
print("일정 위젯 검토판 생성: \(output.path)")
