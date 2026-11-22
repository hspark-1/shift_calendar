import Foundation

enum ShiftWidgetContract {
    static let app_group = "group.com.hspark.shiftmate"
    static let snapshot_key = "shiftmate_widget_snapshot_v1"
    static let widget_kind = "ShiftMateShiftWidget"
    static let tomorrow_widget_kind = "ShiftMateTomorrowShiftWidget"
}

enum ShiftWidgetDay: Int {
    case today = 0
    case tomorrow = 1

    var title: String { self == .today ? "오늘" : "내일" }
    var following_title: String { self == .today ? "내일" : "모레" }
}

/// 같은 스냅샷/기준 시각에서 오늘·내일의 현지 근무일을 선택한다.
struct ShiftWidgetDayContent {
    let reference_date: Date
    let snapshot: ShiftWidgetSnapshot?
    let day: ShiftWidgetDay

    private var calendar: Calendar { snapshot?.calendar ?? .current }
    var target_date: Date? { calendar.date(byAdding: .day, value: day.rawValue, to: reference_date) }
    var following_date: Date? { calendar.date(byAdding: .day, value: day.rawValue + 1, to: reference_date) }
    var is_covered: Bool {
        guard let target_date else { return false }
        return snapshot?.contains(target_date) == true
    }
    var shift: WidgetShift? {
        guard let target_date else { return nil }
        return snapshot?.shift(on: target_date)
    }
    var inline_label: String {
        guard is_covered else { return "ShiftMate · 앱에서 동기화" }
        guard let shift else { return "\(day.title) 등록된 근무 없음" }
        return "\(day.title) \(shift.code) · \(shift.lock_time_label ?? shift.name)"
    }
    var lock_accessibility_label: String {
        guard is_covered else { return "ShiftMate를 열어 근무표 동기화" }
        return "\(day.title) \(shift?.name ?? "등록된 근무 없음") \(shift?.code ?? "") \(shift?.lock_time_label ?? "")"
    }
}

struct WidgetShift: Codable {
    let date: String
    let code: String
    let name: String
    let color: UInt32?
    let start_time: String?
    let end_time: String?

    var time_label: String? {
        formattedTime(include_overnight: true)
    }

    var lock_time_label: String? {
        formattedTime(include_overnight: false)
    }

    private func formattedTime(include_overnight: Bool) -> String? {
        guard let start_time, let end_time,
              Self.isValidTime(start_time), Self.isValidTime(end_time) else { return nil }
        let start = String(start_time.prefix(5))
        let end = String(end_time.prefix(5))
        return "\(start) - \(include_overnight && end < start ? "익일 " : "")\(end)"
    }

    private static func isValidTime(_ value: String) -> Bool {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        guard (2...3).contains(parts.count),
              parts[0].count == 2, parts[1].count == 2,
              let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0...23).contains(hour), (0...59).contains(minute) else { return false }
        return true
    }
}

struct ShiftWidgetSnapshot: Codable {
    let schema_version: Int
    let owner_id: String
    let timezone: String
    let updated_at: String
    let start_date: String
    let end_date: String
    let shifts: [WidgetShift]

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current
        calendar.firstWeekday = 2
        return calendar
    }

    static func decode(_ raw: String?) -> ShiftWidgetSnapshot? {
        guard let raw, let data = raw.data(using: .utf8),
              let snapshot = try? JSONDecoder().decode(Self.self, from: data),
              snapshot.schema_version == 1, !snapshot.owner_id.isEmpty,
              TimeZone(identifier: snapshot.timezone) != nil,
              let start = snapshot.parseDate(snapshot.start_date),
              let end = snapshot.parseDate(snapshot.end_date),
              start <= end,
              let days = snapshot.calendar.dateComponents([.day], from: start, to: end).day,
              days < 93,
              snapshot.updatedDate != nil else { return nil }
        return snapshot
    }

    var updatedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: updated_at) ?? ISO8601DateFormatter().date(from: updated_at)
    }

    func dateKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    func parseDate(_ key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
              dateKey(date) == key else { return nil }
        return date
    }

    func contains(_ date: Date) -> Bool {
        let key = dateKey(date)
        return start_date <= key && key <= end_date
    }

    func shift(on date: Date) -> WidgetShift? {
        guard contains(date) else { return nil }
        return shifts.first { $0.date == dateKey(date) }
    }

    func weekDates(for date: Date, week_offset: Int = 0) -> [Date] {
        let day = calendar.startOfDay(for: date)
        let offset = (calendar.component(.weekday, from: day) + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -offset + week_offset * 7, to: day) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    /// 각 자정과 마지막 조회일 다음 날의 만료 entry를 함께 제공한다.
    func entryDates(from now: Date) -> [Date] {
        guard let end = parseDate(end_date),
              let expiry = calendar.date(byAdding: .day, value: 1, to: end), now < expiry else { return [now] }
        var dates = [now]
        var cursor = calendar.startOfDay(for: now)
        for _ in 0..<94 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor), next <= expiry else { break }
            dates.append(next)
            cursor = next
        }
        return dates
    }

    static func sample(now: Date = Date()) -> ShiftWidgetSnapshot {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let offset = (calendar.component(.weekday, from: now) + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now))!
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        let dates = (0..<14).map { calendar.date(byAdding: .day, value: $0, to: monday)! }
        let codes = ["D", "D", "E", "E", "N", "OFF", "OFF"]
        let shifts = dates.enumerated().map { index, date in
            let code = codes[index % 7]
            return WidgetShift(
                date: formatter.string(from: date), code: code,
                name: code == "OFF" ? "휴무" : ["D": "데이", "E": "이브닝", "N": "나이트"][code]!,
                color: ["D": 0xFFF5A623, "E": 0xFF4CAF50, "N": 0xFF536DFE, "OFF": 0xFF90A4AE][code],
                start_time: code == "OFF" ? nil : ["D": "07:00", "E": "15:00", "N": "23:00"][code],
                end_time: code == "OFF" ? nil : ["D": "15:00", "E": "23:00", "N": "07:00"][code]
            )
        }
        return Self(schema_version: 1, owner_id: "preview", timezone: calendar.timeZone.identifier,
                    updated_at: ISO8601DateFormatter().string(from: now),
                    start_date: formatter.string(from: dates.first!), end_date: formatter.string(from: dates.last!),
                    shifts: shifts)
    }
}
