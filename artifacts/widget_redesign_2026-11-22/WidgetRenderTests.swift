import SwiftUI
import WidgetKit
import XCTest

final class WidgetRenderTests: XCTestCase {
    let output = URL(fileURLWithPath: ProcessInfo.processInfo.environment["WIDGET_RENDER_OUTPUT"]!)

    @MainActor func writeImage<V: View>(_ content: V, name: String, size: CGSize) throws {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.uiImage)
        XCTAssertEqual(image.size, size)
        try XCTUnwrap(image.pngData()).write(to: output.appendingPathComponent("\(name).png"))
    }

    @MainActor func testDesignMatrix() throws {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let formatter = ISO8601DateFormatter()
        let now = formatter.date(from: "2026-11-20T03:00:00Z")!
        let sample = ShiftWidgetSnapshot.sample(now: now)
        func snapshot(_ shifts: [WidgetShift], end: String? = nil) -> ShiftWidgetSnapshot {
            ShiftWidgetSnapshot(schema_version: 1, owner_id: sample.owner_id, timezone: sample.timezone,
                updated_at: sample.updated_at, start_date: sample.start_date, end_date: end ?? sample.end_date, shifts: shifts)
        }
        let long = snapshot(sample.shifts.map {
            WidgetShift(date: $0.date, code: "LONGSHIFT123", name: "아주 긴 사용자 정의 야간 근무", color: 0xFFFFFF00, start_time: "23:00", end_time: "07:00")
        })
        let no_time = snapshot(sample.shifts.map {
            WidgetShift(date: $0.date, code: "OFF", name: "휴무", color: 0xFF90A4AE, start_time: nil, end_time: nil)
        })
        let next_work = snapshot(sample.shifts.enumerated().map { index, shift in
            let code = ["D", "E", "N"][index % 3]
            return WidgetShift(date: shift.date, code: code,
                name: ["D": "데이", "E": "이브닝", "N": "나이트"][code]!, color: 0xFF536DFE,
                start_time: ["D": "07:00", "E": "15:00", "N": "23:00"][code],
                end_time: ["D": "15:00", "E": "23:00", "N": "07:00"][code])
        })
        let families: [(String, WidgetFamily, CGSize)] = [
            ("small", .systemSmall, CGSize(width: 158, height: 158)),
            ("medium", .systemMedium, CGSize(width: 338, height: 158)),
            ("circular", .accessoryCircular, CGSize(width: 76, height: 76)),
            ("rectangular", .accessoryRectangular, CGSize(width: 172, height: 76)),
            ("inline", .accessoryInline, CGSize(width: 300, height: 32))
        ]
        let variants = ["light", "dark", "large", "long", "long-large", "missing", "no-time", "logged-out", "expired", "uncached-next", "year", "narrow", "accented", "vibrant", "narrow-large", "next-work", "next-work-large"]
        for day in [ShiftWidgetDay.today, .tomorrow] {
            for (name, family, default_size) in families where day == .today || family != .systemMedium {
                for variant in variants {
                    if variant == "narrow-large" && family != .accessoryRectangular && family != .systemSmall { continue }
                    if variant.hasPrefix("next-work") && family != .systemSmall { continue }
                    let date = variant == "year" ? formatter.date(from: "2026-12-31T03:00:00Z")! : (variant == "expired" ? formatter.date(from: "2026-12-10T03:00:00Z")! : now)
                    let data: ShiftWidgetSnapshot? = variant == "logged-out" ? nil : (variant.hasPrefix("next-work") ? next_work : (variant == "year" ? .sample(now: date) : (variant.hasPrefix("long") ? long : (variant == "missing" ? snapshot([]) : (variant == "no-time" ? no_time : (variant == "uncached-next" ? snapshot(sample.shifts, end: "2026-11-22") : sample))))))
                    let large = variant == "large" || variant == "long-large" || variant == "narrow-large" || variant == "next-work-large"
                    let dark = variant == "dark" || variant == "accented" || variant == "vibrant"
                    let mode: WidgetRenderingMode = variant == "accented" ? .accented : (variant == "vibrant" ? .vibrant : .fullColor)
                    let size = variant.hasPrefix("narrow") ? CGSize(width: name == "small" ? 140 : (name == "medium" ? 300 : (name == "inline" ? 160 : (name == "rectangular" ? 150 : default_size.width))), height: name == "small" || name == "medium" ? 140 : (name == "rectangular" ? 64 : default_size.height)) : default_size
                    let entry = ShiftEntry(date: date, snapshot: data, day: day)
                    let view = ShiftWidgetView(family: family, entry: entry)
                        .environment(\.colorScheme, dark ? .dark : .light)
                        .environment(\.widgetRenderingMode, mode)
                        .environment(\.dynamicTypeSize, large ? .accessibility5 : .large)
                        .padding(family == .systemSmall || family == .systemMedium ? 16 : 0)
                        .frame(width: size.width, height: size.height, alignment: family == .accessoryInline ? .leading : .center)
                        .background(dark ? Color(red: 0.075, green: 0.085, blue: 0.11) : .white)
                    try writeImage(view, name: "\(day.rawValue)-\(name)-\(variant)", size: size)

                }
            }
        }
    }
}
