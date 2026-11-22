import SwiftUI
import WidgetKit

struct ShiftEntry: TimelineEntry {
    let date: Date
    let snapshot: ShiftWidgetSnapshot?
    var day: ShiftWidgetDay = .today
}

struct ShiftTimelineProvider: TimelineProvider {
    var day: ShiftWidgetDay = .today

    func placeholder(in context: Context) -> ShiftEntry {
        ShiftEntry(date: Date(), snapshot: .sample(), day: day)
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftEntry) -> Void) {
        completion(ShiftEntry(date: Date(), snapshot: context.isPreview ? .sample() : load(), day: day))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftEntry>) -> Void) {
        let now = Date()
        let snapshot = load()
        let dates = snapshot?.entryDates(from: now) ?? [now]
        let entries = dates.map { ShiftEntry(date: $0, snapshot: snapshot, day: day) }
        // 데이터가 만료되어도 마지막 날 근무를 계속 보여주지 않는다.
        completion(Timeline(entries: entries, policy: .after(dates.last!.addingTimeInterval(3600))))
    }

    private func load() -> ShiftWidgetSnapshot? {
        let preferences = UserDefaults(suiteName: ShiftWidgetContract.app_group)
        return .decode(preferences?.string(forKey: ShiftWidgetContract.snapshot_key))
    }
}

private enum WidgetPalette {
    static func primary(is_dark: Bool) -> Color {
        is_dark ? Color(red: 0.62, green: 0.82, blue: 1)
            : Color(red: 0, green: 0.38, blue: 0.64)
    }

    static func secondary(is_dark: Bool) -> Color {
        is_dark ? Color(red: 0.72, green: 0.76, blue: 0.81)
            : Color(red: 0.29, green: 0.32, blue: 0.36)
    }

    static func background(is_dark: Bool) -> Color {
        is_dark ? Color(red: 0.075, green: 0.085, blue: 0.11) : .white
    }
}

struct ShiftWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ShiftEntry

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                ShiftWidgetRenderingContent(family: family, entry: entry)
            } else {
                ShiftWidgetContent(family: family, entry: entry, is_full_color: true)
            }
        }
        // 고정 면적에서 핵심 근무를 보존하고 전체 내용은 VoiceOver로 제공한다.
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .privacySensitive()
        .accessibilityElement(children: .contain)
    }
}

// renderingMode는 iOS16부터 읽고 iOS15 홈 위젯은 full color로 유지한다.
@available(iOS 16.0, *)
private struct ShiftWidgetRenderingContent: View {
    @Environment(\.widgetRenderingMode) private var rendering_mode
    let family: WidgetFamily
    let entry: ShiftEntry

    var body: some View {
        ShiftWidgetContent(family: family, entry: entry, is_full_color: rendering_mode == .fullColor)
    }
}

private struct ShiftWidgetContent: View {
    @Environment(\.colorScheme) private var color_scheme
    @ScaledMetric(relativeTo: .largeTitle) private var code_size = 32.0
    @ScaledMetric(relativeTo: .title3) private var day_time_size = 18.0
    @ScaledMetric(relativeTo: .title2) private var lock_time_size = 22.0
    let family: WidgetFamily
    let entry: ShiftEntry
    let is_full_color: Bool

    private var snapshot: ShiftWidgetSnapshot? { entry.snapshot }
    private var day_content: ShiftWidgetDayContent {
        ShiftWidgetDayContent(reference_date: entry.date, snapshot: snapshot, day: entry.day)
    }
    private var target_shift: WidgetShift? { day_content.shift }
    private var is_covered: Bool { day_content.is_covered }
    private var is_dark: Bool { color_scheme == .dark }
    private var accent: Color { is_full_color ? WidgetPalette.primary(is_dark: is_dark) : .white }
    private var ink: Color { is_full_color ? .primary : .white }
    private var secondary: Color { is_full_color ? WidgetPalette.secondary(is_dark: is_dark) : .white }
    private var is_home: Bool { family == .systemSmall || family == .systemMedium }

    var body: some View {
        Group {
            if #available(iOS 16.0, *), family == .accessoryCircular {
                circular
            } else if #available(iOS 16.0, *), family == .accessoryRectangular {
                rectangular
            } else if #available(iOS 16.0, *), family == .accessoryInline {
                inline
            } else {
                home_content
            }
        }
        .foregroundColor(ink)
        .widgetSurface(is_home: is_home, background: WidgetPalette.background(is_dark: is_dark),
                       is_full_color: is_full_color)
    }

    @ViewBuilder private var home_content: some View {
        if !is_covered {
            sync_content
        } else if family == .systemMedium {
            weekly
        } else if #available(iOS 16.0, *) {
            ViewThatFits(in: .vertical) {
                daily(compact: false)
                daily(compact: true)
            }
        } else {
            daily(compact: true)
        }
    }

    private var sync_content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("근무표", systemImage: "calendar")
                .font(.caption.weight(.semibold)).foregroundColor(accent)
                .shiftAccent()
            Spacer(minLength: 0)
            Text("동기화 필요").font(.headline)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text("앱에서 근무표 확인")
                .font(.caption).foregroundColor(secondary)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.day.title) 근무표 동기화 필요. ShiftMate 앱에서 근무표를 동기화하세요.")
    }

    private func daily(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(entry.day.title).font(.caption.weight(.bold))
                    .foregroundColor(accent).shiftAccent()
                Spacer(minLength: 0)
                Text(label(for: day_content.target_date ?? entry.date, format: "M.d E"))
                    .font(.caption2.weight(.medium)).foregroundColor(secondary)
            }
            .lineLimit(1).minimumScaleFactor(0.7)
            shiftSummary(compact: compact)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(entry.day.title) \(target_shift?.name ?? "등록된 근무 없음") \(target_shift?.code ?? "")")
            dailyTimes(compact: compact)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            following_shift
        }
    }

    @ViewBuilder private func shiftSummary(compact: Bool) -> some View {
        if let target_shift {
            if #available(iOS 16.0, *) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 8) {
                        codeBadge(compact: compact).fixedSize()
                        Text(target_shift.name).font(.subheadline.weight(.semibold)).fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(target_shift.code).font(.title3.bold())
                            .foregroundColor(accent).shiftAccent()
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text(target_shift.name).font(.caption)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                }
            } else {
                Text("\(target_shift.code) · \(target_shift.name)")
                    .font(.title3.bold()).foregroundColor(accent)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
        } else {
            Text("근무 미등록").font(.headline).foregroundColor(accent).shiftAccent()
                .lineLimit(2).minimumScaleFactor(0.7)
        }
    }

    private func codeBadge(compact: Bool) -> some View {
        Text(target_shift?.code ?? "—")
            .font(.system(size: min(code_size, compact ? 28 : 36), weight: .bold, design: .rounded))
            .foregroundColor(accent).shiftAccent()
            .padding(.horizontal, 8).padding(.vertical, 2)
            .frame(minWidth: 40)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(is_full_color ? shiftColor(target_shift).opacity(is_dark ? 0.18 : 0.12) : .clear))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .strokeBorder(is_full_color ? .clear : ink, lineWidth: 1))
    }

    @ViewBuilder private func dailyTimes(compact: Bool) -> some View {
        if let shift = target_shift {
            if shift.time_label != nil, let start_time = shift.start_time, let end_time = shift.end_time {
                // time_label이 검증한 HH:mm 값만 두 열로 나눈다.
                let start = String(start_time.prefix(5))
                let end = String(end_time.prefix(5))
                HStack(alignment: .top, spacing: 8) {
                    timeColumn(title: "시작", value: start, compact: compact)
                    timeColumn(title: end < start ? "익일 종료" : "종료", value: end, compact: compact)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("시작 \(start), \(end < start ? "익일 " : "")종료 \(end)")
            } else {
                Text("시간 지정 없음").font(.caption).foregroundColor(secondary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
        }
    }

    private func timeColumn(title: String, value: String, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.caption2).foregroundColor(secondary)
                .lineLimit(1).minimumScaleFactor(0.65)
            Text(value).font(.system(size: min(day_time_size, compact ? 18 : 22), weight: .semibold))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var following_shift: some View {
        if let snapshot, let following_date = day_content.following_date {
            let shift = snapshot.shift(on: following_date)
            let covered = snapshot.contains(following_date)
            let detail = shift?.time_label?.replacingOccurrences(of: " - ", with: "–")
                .replacingOccurrences(of: "익일 ", with: "익일") ?? shift?.name
            Group {
                if #available(iOS 16.0, *), covered, let shift {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 4) {
                            Text("\(entry.day.following_title) \(shift.code)").fontWeight(.semibold).fixedSize()
                            Spacer(minLength: 0)
                            Text(detail ?? shift.name)
                                .foregroundColor(secondary).fixedSize()
                        }
                        followingCode(shift: shift, covered: covered)
                    }
                } else if covered, let shift {
                    Text("\(entry.day.following_title) \(shift.code) · \(detail ?? shift.name)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    followingCode(shift: shift, covered: covered)
                }
            }
            .font(.caption2).lineLimit(1).minimumScaleFactor(0.8)
            .padding(.top, 5)
            .overlay(alignment: .top) {
                Rectangle().fill(secondary.opacity(0.25)).frame(height: 0.5)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(entry.day.following_title) \(covered ? (shift.map { "\($0.name) \($0.code) \($0.time_label ?? "")" } ?? "등록된 근무 없음") : "근무표 동기화 필요")")
        }
    }

    private func followingCode(shift: WidgetShift?, covered: Bool) -> some View {
        HStack(spacing: 4) {
            Text(entry.day.following_title).foregroundColor(secondary)
            Spacer(minLength: 0)
            Text(covered ? (shift?.code ?? "미등록") : "동기화 필요").fontWeight(.semibold)
        }
    }

    private var weekly: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let snapshot {
                let days = snapshot.weekDates(for: entry.date)
                let next_days = snapshot.weekDates(for: entry.date, week_offset: 1)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("2주 근무").font(.caption.weight(.bold))
                        .foregroundColor(accent).shiftAccent()
                    Spacer(minLength: 0)
                    if let first = days.first, let last = next_days.last {
                        Text(rangeLabel(from: first, to: last))
                            .font(.caption2).foregroundColor(secondary)
                    }
                }
                .lineLimit(1).minimumScaleFactor(0.7)
                HStack(spacing: 4) {
                    ForEach(days, id: \.self) { date in
                        Text(label(for: date, format: "E"))
                            .font(.caption2.weight(.medium)).foregroundColor(secondary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                }
                .accessibilityHidden(true)
                weekRow(days)
                weekRow(next_days)
            }
        }
    }

    @ViewBuilder private func weekRow(_ days: [Date]) -> some View {
        if let snapshot {
            HStack(spacing: 4) {
                ForEach(days, id: \.self) { date in
                    let shift = snapshot.shift(on: date)
                    let is_today = snapshot.calendar.isDate(date, inSameDayAs: entry.date)
                    VStack(spacing: 2) {
                        Text(label(for: date, format: "d"))
                            .font(.caption2.weight(is_today ? .bold : .medium))
                            .foregroundColor(is_today && is_full_color ? (is_dark ? .black : .white) : ink)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Capsule().fill(is_today && is_full_color ? accent : .clear))
                            .overlay(Capsule().strokeBorder(is_today && !is_full_color ? ink : .clear, lineWidth: 1.5))
                            .shiftAccent(is_today)
                        Text(snapshot.contains(date) ? (shift?.code ?? "—") : "·")
                            .font(.caption.weight(is_today ? .bold : .semibold))
                            .lineLimit(1).minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity, minHeight: 20)
                            .background(RoundedRectangle(cornerRadius: 5)
                                .fill(is_full_color ? shiftColor(shift).opacity(is_dark ? 0.25 : 0.16) : .clear))
                            .shiftAccent(is_today)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(label(for: date, format: "M월 d일 EEEE")), \(is_today ? "오늘, " : "")\(snapshot.contains(date) ? (shift.map { "\($0.name) \($0.code)" } ?? "등록된 근무 없음") : "동기화 필요") \(shift?.time_label ?? "")")
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    @available(iOS 16.0, *)
    private var inline: some View {
        Text(day_content.inline_label)
            .lineLimit(1)
            .accessibilityLabel(day_content.lock_accessibility_label)
    }

    @available(iOS 16.0, *)
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(is_covered ? entry.day.title : "근무표").font(.caption2.weight(.medium))
                Text(is_covered ? (target_shift?.code ?? "—") : "동기화")
                    .font(.title2.bold()).lineLimit(1).minimumScaleFactor(0.35)
                    .widgetAccentable()
            }
            .padding(4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day_content.lock_accessibility_label)
    }

    @available(iOS 16.0, *)
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 4) {
            if is_covered {
                Text("\(entry.day.title) \(target_shift?.code ?? "—") · \(target_shift?.name ?? "미등록")")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1).truncationMode(.tail)
                    .widgetAccentable()
                if let time = target_shift?.lock_time_label {
                    Text(time.replacingOccurrences(of: " - ", with: "–"))
                        .font(.system(size: min(lock_time_size, 26), weight: .semibold))
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.85)
                        .layoutPriority(1)
                } else {
                    Text(target_shift == nil ? "등록된 근무 없음" : "시간 지정 없음")
                        .font(.headline).lineLimit(1).minimumScaleFactor(0.85)
                }
            } else {
                Text("근무표 동기화 필요").font(.headline).lineLimit(1).minimumScaleFactor(0.6)
                Text("앱에서 근무표 확인").font(.caption).lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day_content.lock_accessibility_label)
    }

    private func shiftColor(_ shift: WidgetShift?) -> Color {
        guard let value = shift?.color else { return accent }
        return Color(.sRGB, red: Double((value >> 16) & 255) / 255,
                     green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255,
                     opacity: Double((value >> 24) & 255) / 255)
    }

    private func rangeLabel(from first: Date, to last: Date) -> String {
        let crosses_year = snapshot?.calendar.component(.year, from: first)
            != snapshot?.calendar.component(.year, from: last)
        let format = crosses_year ? "yy.M.d" : "M.d"
        return "\(label(for: first, format: format)) – \(label(for: last, format: format))"
    }

    private func label(for date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = snapshot?.calendar ?? Calendar(identifier: .gregorian)
        formatter.timeZone = snapshot?.calendar.timeZone ?? .current
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

private extension View {
    @ViewBuilder func shiftAccent(_ enabled: Bool = true) -> some View {
        if #available(iOS 16.0, *) {
            widgetAccentable(enabled)
        } else {
            self
        }
    }

    @ViewBuilder func widgetSurface(is_home: Bool, background: Color, is_full_color: Bool) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) {
                if is_home && is_full_color { background }
            }
        } else if is_home {
            padding(16).background(background)
        } else {
            self
        }
    }
}

struct ShiftMateShiftWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ShiftWidgetContract.widget_kind, provider: ShiftTimelineProvider()) { entry in
            ShiftWidgetView(entry: entry)
        }
        .configurationDisplayName("오늘 근무")
        .description("오늘의 근무와 시간을 한눈에. 중형은 이번 주와 다음 주를 함께 보여줍니다.")
        .supportedFamilies(families)
    }

    private var families: [WidgetFamily] {
        if #available(iOS 16.0, *) {
            return [.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        }
        return [.systemSmall, .systemMedium]
    }
}

struct ShiftMateTomorrowShiftWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ShiftWidgetContract.tomorrow_widget_kind,
                            provider: ShiftTimelineProvider(day: .tomorrow)) { entry in
            ShiftWidgetView(entry: entry)
        }
        .configurationDisplayName("내일 근무")
        .description("내일의 근무와 시간을 미리 확인하세요. 소형에서는 모레 근무도 함께 보여줍니다.")
        .supportedFamilies(families)
    }

    private var families: [WidgetFamily] {
        if #available(iOS 16.0, *) {
            return [.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        }
        return [.systemSmall]
    }
}

@main
struct ShiftMateWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShiftMateShiftWidget()
        ShiftMateTomorrowShiftWidget()
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("오늘 근무", as: .systemSmall) {
    ShiftMateShiftWidget()
} timeline: {
    ShiftEntry(date: .now, snapshot: .sample())
}

@available(iOS 17.0, *)
#Preview("2주 근무", as: .systemMedium) {
    ShiftMateShiftWidget()
} timeline: {
    ShiftEntry(date: .now, snapshot: .sample())
}

@available(iOS 17.0, *)
#Preview("내일 근무", as: .systemSmall) {
    ShiftMateTomorrowShiftWidget()
} timeline: {
    ShiftEntry(date: .now, snapshot: .sample(), day: .tomorrow)
}

@available(iOS 17.0, *)
#Preview("잠금 원형", as: .accessoryCircular) {
    ShiftMateShiftWidget()
} timeline: {
    ShiftEntry(date: .now, snapshot: .sample())
}

@available(iOS 17.0, *)
#Preview("잠금 직사각형", as: .accessoryRectangular) {
    ShiftMateShiftWidget()
} timeline: {
    ShiftEntry(date: .now, snapshot: .sample())
}

@available(iOS 17.0, *)
#Preview("잠금 한 줄", as: .accessoryInline) {
    ShiftMateShiftWidget()
} timeline: {
    ShiftEntry(date: .now, snapshot: .sample())
}
#endif
