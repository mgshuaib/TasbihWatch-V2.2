//
//  TasbihWidget.swift
//  سبحة — ودجت Smart Stack (يعرض المجموعة الحالية والذكر الحالي)
//
//  يمكن تسجيل ذكر من داخل الودجت نفسه — باللمس أو بالضغط المزدوج.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - البيانات

struct TasbihEntry: TimelineEntry {
    let date: Date
    let setTitle: String
    let dhikrText: String
    let count: Int
    let target: Int          // 0 = بلا حد
    let position: String     // "٣/٧"

    // إعدادات يختارها المستخدم من القائمة المنسدلة في التطبيق
    var mode: WidgetMode = .current
    var showsPlus: Bool = true
    var showsSetName: Bool = true
    var totalToday: Int = 0
    var setProgress: Double = 0     // تقدّم المجموعة (لنمط الملخّص)

    var progress: Double {
        target > 0 ? min(1, Double(count) / Double(target)) : 0
    }
    var isUnlimited: Bool { target <= 0 }
}

// MARK: - المزوّد

struct TasbihProvider: TimelineProvider {

    func placeholder(in context: Context) -> TasbihEntry {
        TasbihEntry(date: .now, setTitle: "أذكار بعد الصلاة", dhikrText: "سُبْحَانَ اللَّه",
                     count: 12, target: 33, position: "4/7")
    }

    func getSnapshot(in context: Context, completion: @escaping (TasbihEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasbihEntry>) -> Void) {
        // يُحدَّث فوريًا بعد كل تعديل عبر WidgetCenter.shared.reloadAllTimelines()
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> TasbihEntry {
        let st = SharedCounter.state()
        let set = SharedCounter.currentSet(st)
        let dhikr = SharedCounter.currentDhikr(st)
        let cfg = WidgetConfig.snapshot()

        let setProgress = set.items.isEmpty
            ? 0
            : Double(st.itemIndex) / Double(set.items.count)

        return TasbihEntry(
            date: .now,
            setTitle: set.title,
            dhikrText: st.isSetDone ? "تمّت المجموعة ✅" : dhikr.text,
            count: st.count,
            target: dhikr.target,
            position: "\(st.itemIndex + 1)/\(set.items.count)",
            mode: cfg.mode,
            showsPlus: cfg.plus,
            showsSetName: cfg.set,
            totalToday: st.totalToday,
            setProgress: setProgress
        )
    }
}

// MARK: - الواجهة

struct TasbihWidgetView: View {
    var entry: TasbihEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        default:                 rectangular
        }
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            progressRing(size: 32)

            VStack(alignment: .leading, spacing: 1) {
                if entry.showsSetName {
                    Text(entry.setTitle)
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.teal)
                        .lineLimit(1)
                }

                if entry.mode == .summary {
                    // نمط الملخّص: الموضع + إجمالي اليوم
                    Text("الموضع \(entry.position)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Text("اليوم: \(entry.totalToday)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } else {
                    Text(entry.dhikrText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Text(entry.isUnlimited ? "\(entry.count) · بلا حد"
                                           : "\(entry.count) / \(entry.target) · \(entry.position)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // زر التسجيل: يظهر في نمط «الذكر الحالي» وفقط إن فعّله المستخدم
            if entry.mode == .current && entry.showsPlus {
                Button(intent: IncrementDhikrIntent()) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .primaryTapShortcut()
                .accessibilityLabel("تسجيل ذكر")
            }
        }
        .containerBackground(for: .widget) { Color.black }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            progressRing(size: 44, lineWidth: 4,
                         value: entry.mode == .summary ? entry.setProgress : entry.progress)
            VStack(spacing: -2) {
                if entry.mode == .summary {
                    Text("\(Int(entry.setProgress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("المجموعة")
                        .font(.system(size: 7, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(entry.count)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(entry.isUnlimited ? "∞" : "/ \(entry.target)")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(for: .widget) { Color.black }
    }

    private func progressRing(size: CGFloat, lineWidth: CGFloat = 5,
                              value: Double? = nil) -> some View {
        ZStack {
            Circle().stroke(.white.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: value ?? entry.progress)
                .stroke(.teal, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - التعريف

struct TasbihWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TasbihWidget", provider: TasbihProvider()) { entry in
            TasbihWidgetView(entry: entry)
        }
        .configurationDisplayName("سبحة")
        .description("تابع المجموعة الحالية وسجّل الأذكار بإيماءة، بدون فتح التطبيق.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

@main
struct TasbihWidgetBundle: WidgetBundle {
    var body: some Widget { TasbihWidget() }
}
