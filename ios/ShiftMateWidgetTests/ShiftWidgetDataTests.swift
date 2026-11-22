// Foundation 단독 회귀: 문서의 swiftc 명령으로 실제 제품 모델과 함께 실행한다.
import Foundation

@main
struct ShiftWidgetDataTests {
    struct Failure: Error { let message: String }

    static func main() throws {
        var checks = 0
        func expect(_ condition: Bool, _ message: String) throws {
            guard condition else { throw Failure(message: message) }
            checks += 1
        }
        let raw = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
        guard let snapshot = ShiftWidgetSnapshot.decode(raw) else { throw Failure(message: "Dart JSON decode") }
        try expect(snapshot.owner_id == "contract-owner", "Dart owner")
        let today = snapshot.parseDate("2026-11-21")!
        try expect(snapshot.eventCount(on: today) == 2, "Dart event count")
        try expect(snapshot.eventCount(on: snapshot.parseDate("2026-11-22")!) == 0, "known zero events")
        try expect(snapshot.eventCount(on: snapshot.parseDate("2026-12-28")!) == nil, "uncovered event count is unknown")
        let events_content = ShiftWidgetDayContent(reference_date: today, snapshot: snapshot, day: .today)
        try expect(events_content.inline_label == "오늘 · 일정 2개 · N 23:00 - 07:00", "inline surfaces events before time")
        try expect(events_content.lock_accessibility_label.contains("개인 일정 2개"), "VoiceOver event context")
        var many = snapshot
        many.event_counts = [snapshot.dateKey(today): 123]
        let many_content = ShiftWidgetDayContent(reference_date: today, snapshot: many, day: .today)
        try expect(many_content.event_label == "일정 99+개", "large count stays compact")
        try expect(many_content.lock_accessibility_label.contains("개인 일정 123개"), "large count VoiceOver stays exact")
        var legacy_json = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as! [String: Any]
        legacy_json.removeValue(forKey: "event_counts")
        let legacy_raw = String(data: try JSONSerialization.data(withJSONObject: legacy_json), encoding: .utf8)!
        let legacy = ShiftWidgetSnapshot.decode(legacy_raw)
        try expect(legacy?.shift(on: today)?.code == "N", "old cache keeps shifts")
        try expect(legacy?.eventCount(on: today) == nil, "old cache does not invent zero events")
        let invalid_cases: [[String: Any]] = [["2026-11-21": -1], ["2026-02-30": 1], ["2026-12-28": 1], ["2026-11-21": "2"]]
        for invalid_counts in invalid_cases {
            var invalid_json = legacy_json
            invalid_json["event_counts"] = invalid_counts
            let invalid_raw = String(data: try JSONSerialization.data(withJSONObject: invalid_json), encoding: .utf8)!
            try expect(ShiftWidgetSnapshot.decode(invalid_raw) == nil, "invalid event counts rejected")
        }
        try expect(snapshot.shift(on: today)?.code == "N", "Dart date/code")
        try expect(snapshot.shift(on: today)?.time_label == "23:00 - 익일 07:00", "overnight")
        try expect(snapshot.shift(on: today)?.lock_time_label == "23:00 - 07:00", "lock screen hides generated overnight label")
        try expect(ShiftWidgetContract.widget_kind != ShiftWidgetContract.tomorrow_widget_kind, "distinct kind identities")
        let next_date = snapshot.calendar.date(byAdding: .day, value: 1, to: today)!
        let tomorrow_shift = WidgetShift(date: snapshot.dateKey(next_date), code: "CUSTOM", name: "사용자 근무", color: nil, start_time: "22:00", end_time: "06:00")
        let both_days = ShiftWidgetSnapshot(schema_version: 1, owner_id: snapshot.owner_id, timezone: snapshot.timezone,
            updated_at: snapshot.updated_at, start_date: snapshot.start_date, end_date: snapshot.end_date,
            shifts: snapshot.shifts + [tomorrow_shift])
        let today_content = ShiftWidgetDayContent(reference_date: today, snapshot: both_days, day: .today)
        let tomorrow_content = ShiftWidgetDayContent(reference_date: today, snapshot: both_days, day: .tomorrow)
        try expect(today_content.shift?.code == "N", "today selects today's shift")
        try expect(tomorrow_content.shift?.code == "CUSTOM", "tomorrow selects custom code")
        try expect(today_content.inline_label == "오늘 N · 23:00 - 07:00", "today compact inline")
        try expect(tomorrow_content.inline_label == "내일 CUSTOM · 22:00 - 06:00", "tomorrow compact inline")
        try expect(!tomorrow_content.lock_accessibility_label.contains("익일"), "lock accessibility uses compact time")
        try expect(ShiftWidgetDay.tomorrow.following_title == "모레", "tomorrow footer label")
        try expect(snapshot.dateKey(tomorrow_content.following_date!) == "2026-11-23", "day after tomorrow footer date")
        let next_midnight = ShiftWidgetDayContent(reference_date: next_date, snapshot: both_days, day: .tomorrow)
        try expect(snapshot.dateKey(next_midnight.target_date!) == "2026-11-23", "tomorrow advances at midnight")
        let last_covered = snapshot.parseDate(snapshot.end_date)!
        let end_today = ShiftWidgetDayContent(reference_date: last_covered, snapshot: snapshot, day: .today)
        let end_tomorrow = ShiftWidgetDayContent(reference_date: last_covered, snapshot: snapshot, day: .tomorrow)
        try expect(end_today.is_covered, "last day still covers today")
        try expect(!end_tomorrow.is_covered, "tomorrow expires one day earlier")
        try expect(end_tomorrow.event_count == nil, "expired target has no event indicator")
        try expect(end_tomorrow.inline_label == "ShiftMate · 앱에서 동기화", "out of coverage prompts sync")
        let missing = ShiftWidgetDayContent(reference_date: next_date, snapshot: snapshot, day: .tomorrow)
        try expect(missing.inline_label == "내일 등록된 근무 없음", "known missing is not expired")
        let logged_out = ShiftWidgetDayContent(reference_date: today, snapshot: nil, day: .tomorrow)
        try expect(!logged_out.is_covered, "tomorrow logged out")
        try expect(logged_out.event_label == nil, "logged out has no event indicator")
        try expect(snapshot.weekDates(for: today).map(snapshot.dateKey).first == "2026-11-16", "Monday week")
        let current_week = snapshot.weekDates(for: today)
        let next_week = snapshot.weekDates(for: today, week_offset: 1)
        try expect(next_week.map(snapshot.dateKey).first == "2026-11-23", "next week starts on Monday")
        try expect(next_week.map(snapshot.dateKey).last == "2026-11-29", "next week ends on Sunday")
        try expect(Set((current_week + next_week).map(snapshot.dateKey)).count == 14, "two distinct seven-day rows")
        try expect(snapshot.calendar.dateComponents([.day], from: current_week.last!, to: next_week.first!).day == 1, "rows have no skipped day")
        let year_week = snapshot.weekDates(for: snapshot.parseDate("2026-12-27")!, week_offset: 1)
        try expect(year_week.map(snapshot.dateKey).first == "2026-12-28" && year_week.map(snapshot.dateKey).last == "2027-01-03", "next week crosses year boundary")
        try expect(year_week.allSatisfy { !snapshot.contains($0) }, "uncached next week stays unknown")
        let dates = snapshot.entryDates(from: today.addingTimeInterval(1))
        try expect(dates.first == today.addingTimeInterval(1), "initial instant")
        try expect(snapshot.dateKey(dates.last!) == "2026-12-28", "expiry entry")
        try expect(!snapshot.contains(dates.last!), "expired is not no-shift")
        try expect(snapshot.shift(on: snapshot.parseDate("2026-11-22")!) == nil, "missing shift")
        try expect(snapshot.contains(snapshot.parseDate("2026-11-22")!), "known empty coverage")
        try expect(ShiftWidgetSnapshot.decode(nil) == nil, "logged out")
        try expect(ShiftWidgetSnapshot.decode("broken") == nil, "corrupt cache")
        try expect(ShiftWidgetSnapshot.decode(raw.replacingOccurrences(of: "\"schema_version\":1", with: "\"schema_version\":2")) == nil, "future schema")
        try expect(ShiftWidgetSnapshot.decode(raw.replacingOccurrences(of: "Asia/Seoul", with: "Invalid/Zone")) == nil, "invalid timezone")
        try expect(snapshot.parseDate("2026-02-30") == nil, "invalid date normalization")
        let off = WidgetShift(date: "2026-11-21", code: "OFF", name: "휴무", color: nil, start_time: nil, end_time: nil)
        try expect(off.time_label == nil, "no time is not midnight")
        try expect(off.lock_time_label == nil, "lock OFF does not fabricate time")
        let off_snapshot = ShiftWidgetSnapshot(schema_version: 1, owner_id: snapshot.owner_id, timezone: snapshot.timezone,
            updated_at: snapshot.updated_at, start_date: snapshot.start_date, end_date: snapshot.end_date, shifts: [off])
        try expect(ShiftWidgetDayContent(reference_date: today, snapshot: off_snapshot, day: .today).inline_label == "오늘 OFF · 휴무", "OFF inline keeps custom code/name")
        let utc_evening = ISO8601DateFormatter().date(from: "2026-11-21T16:00:00Z")!
        let local_tomorrow = ShiftWidgetDayContent(reference_date: utc_evening, snapshot: snapshot, day: .tomorrow)
        try expect(snapshot.dateKey(local_tomorrow.target_date!) == "2026-11-23", "tomorrow uses owner local date instead of UTC date")
        let new_year = ShiftWidgetDayContent(reference_date: snapshot.parseDate("2026-12-31")!, snapshot: snapshot, day: .tomorrow)
        try expect(snapshot.dateKey(new_year.target_date!) == "2027-01-01", "tomorrow crosses year boundary")
        let invalid = WidgetShift(date: "2026-11-21", code: "D", name: "데이", color: nil, start_time: "25:00", end_time: "07:00")
        try expect(invalid.time_label == nil, "invalid time")
        let dst = ShiftWidgetSnapshot(schema_version: 1, owner_id: "dst", timezone: "America/New_York", updated_at: snapshot.updated_at, start_date: "2026-10-26", end_date: "2026-11-08", shifts: [])
        let dst_start = dst.parseDate("2026-11-01")!
        let dst_dates = dst.entryDates(from: dst_start)
        try expect(dst_dates[1].timeIntervalSince(dst_dates[0]) == 25 * 3600, "DST 25-hour day")
        try expect(dst.weekDates(for: dst_start, week_offset: 1).map(dst.dateKey).first == "2026-11-02", "next week across 25-hour day")
        let dst_tomorrow = ShiftWidgetDayContent(reference_date: dst_start, snapshot: dst, day: .tomorrow)
        try expect(dst.dateKey(dst_tomorrow.target_date!) == "2026-11-02", "tomorrow uses calendar on 25-hour day")
        try expect(dst_tomorrow.target_date!.timeIntervalSince(dst_start) == 25 * 3600, "tomorrow is not fixed 24 hours")
        try expect(dst_dates.map(dst.dateKey).count == Set(dst_dates.map(dst.dateKey)).count, "DST no duplicate day")
        try expect(zip(dst_dates, dst_dates.dropFirst()).allSatisfy { $0 < $1 }, "monotonic timeline")
        let spring = ShiftWidgetSnapshot(schema_version: 1, owner_id: "dst", timezone: "America/New_York", updated_at: snapshot.updated_at, start_date: "2026-03-02", end_date: "2026-03-15", shifts: [])
        let spring_dates = spring.entryDates(from: spring.parseDate("2026-03-08")!)
        try expect(spring_dates[1].timeIntervalSince(spring_dates[0]) == 23 * 3600, "DST 23-hour day")
        try expect(spring.weekDates(for: spring.parseDate("2026-03-08")!, week_offset: 1).map(spring.dateKey).first == "2026-03-09", "next week across 23-hour day")
        let spring_tomorrow = ShiftWidgetDayContent(reference_date: spring.parseDate("2026-03-08")!, snapshot: spring, day: .tomorrow)
        try expect(spring.dateKey(spring_tomorrow.target_date!) == "2026-03-09", "tomorrow uses calendar on 23-hour day")
        try expect(snapshot.entryDates(from: dates.last!.addingTimeInterval(1)).count == 1, "expired timeline")
        print("Swift widget contract/timeline: \(checks) checks passed")
    }
}
