import AppKit
import Foundation
let base_url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("artifacts/design_update_2026-11-10")
let items = [("main_tabs", "캘린더 · 고정 하단 탭"), ("main_tabs_friend", "친구 · 그룹 전환"), ("settings", "설정"), ("shift_type_form", "근무 타입 추가"), ("personal_event_form", "개인 일정 추가"), ("group_edit", "그룹 정보 수정"), ("color_picker", "색상 선택"), ("custom_color", "커스텀 색상"), ("notification_card", "알림 버튼")]
let image_width: CGFloat = 390
let image_height: CGFloat = 844
let row_height = image_height + 54
let canvas = NSImage(size: NSSize(width: image_width * 3, height: row_height * 3))
canvas.lockFocus()
NSColor.white.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvas.size)).fill()
for (index, item) in items.enumerated() {
    let x = CGFloat(index % 3) * image_width
    let row_top = canvas.size.height - CGFloat(index / 3) * row_height
    let label = item.1 as NSString
    label.draw(at: NSPoint(x: x + 16, y: row_top - 38), withAttributes: [.font: NSFont.systemFont(ofSize: 23, weight: .semibold), .foregroundColor: NSColor.black])
    guard let source = NSImage(contentsOf: base_url.appendingPathComponent(item.0 + ".png")) else { fatalError("Missing capture: " + item.0) }
    source.draw(in: NSRect(x: x, y: row_top - row_height, width: image_width, height: image_height))
}
canvas.unlockFocus()
guard let tiff = canvas.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("PNG encoding failed") }
try png.write(to: base_url.appendingPathComponent("comparison.png"))
