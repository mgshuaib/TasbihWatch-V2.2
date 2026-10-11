//
//  StatsView.swift
//  سبحة — شاشة الإحصاءات (عدد اليوم · آخر ٧ أيام · سلسلة الأيام · الإجمالي)
//
//  📊 تُقرأ البيانات من مجموعة التطبيق نفسها التي يكتب فيها العدّ (SharedCounter)،
//     فالإحصاء يجمع عدّ الساعة وعدّ الودجت معًا تلقائيًا.
//

import SwiftUI

struct StatsView: View {

    @Environment(\.dismiss) private var dismiss

    private let week = HistoryStore.last7()
    private let streak = HistoryStore.streak()
    private let today = HistoryStore.today()
    private let total = HistoryStore.totalAllTime()

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                headline
                weekCard
                footerNote
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .sabhaScreenBackground()
        .navigationTitle("إحصاءاتك")
    }

    // MARK: - العدد الكبير

    private var headline: some View {
        VStack(spacing: 2) {
            Text("\(today)")
                .font(SabhaFont.numeral(46, weight: .bold))
                .foregroundStyle(SabhaColor.emerald)
                .contentTransition(.numericText())
                .sabhaGlow(radius: 16, opacity: 0.4)
            Text("ذكرًا اليوم")
                .font(SabhaFont.ui(11, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                SabhaChip(symbol: "flame.fill", text: "\(streak) يوم متتالي", tint: SabhaColor.amber)
                SabhaChip(symbol: "infinity", text: "الإجمالي \(total)", tint: SabhaColor.teal)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .sabhaCard(padding: 12)
    }

    // MARK: - أعمدة آخر ٧ أيام

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("آخر ٧ أيام")
                .font(SabhaFont.ui(11, weight: .semibold))
                .foregroundStyle(.secondary)

            let peak = max(week.map { $0.count }.max() ?? 0, 1)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 4) {
                        Text(day.count == 0 ? "" : "\(day.count)")
                            .font(SabhaFont.numeral(8, weight: .semibold))
                            .foregroundStyle(day.isToday ? SabhaColor.emerald : .secondary)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(day.isToday ? AnyShapeStyle(SabhaGradient.bar)
                                              : AnyShapeStyle(Color.white.opacity(0.14)))
                            .frame(height: max(4, 46 * CGFloat(day.count) / CGFloat(peak)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(day.isToday ? SabhaColor.emerald.opacity(0.5) : .clear, lineWidth: 0.8)
                            )

                        Text(day.label)
                            .font(SabhaFont.ui(8))
                            .foregroundStyle(day.isToday ? SabhaColor.emerald : .secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 78, alignment: .bottom)
        }
        .sabhaCard()
    }

    private var footerNote: some View {
        Text("تُحسب كل ذكر تسجّله — من الساعة أو من ودجت Smart Stack — في يومه تلقائيًا.")
            .font(SabhaFont.ui(9))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 6)
    }
}
