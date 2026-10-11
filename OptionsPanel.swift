//
//  OptionsPanel.swift
//  سبحة — القائمة المنسدلة ☰ (تُفتح من زر واحد أسفل الشاشة في صف الأدوات)
//
//  تحتوي كل شيء: العرض · التلقين · المجموعات · إعدادات الودجت · النظام.
//  تظهر كطبقة فوق شاشة العدّ، بثلاث صفحات (local pages) بدل قوائم متداخلة.
//
//  ⚠️ ملاحظة RTL: في واجهة عربية يكون `.topTrailing` هو **اليسار** فعليًا،
//      ولذلك نثبّت القائمة_عليه، والزر في صف الأدوات أسفل الشاشة (زر واحد لا اثنان).
//

import SwiftUI

// MARK: - صفحات القائمة

enum PanelPage {
    case main, sets, widget
}

// MARK: - اللوحة

struct OptionsPanel: View {

    @ObservedObject var model: CounterModel
    @ObservedObject var session: SessionManager
    var onClose: () -> Void

    @State private var page: PanelPage = .main

    var body: some View {
        ZStack(alignment: .topTrailing) {          // RTL: اليسار فعليًا

            // خلفية معتمة تُغلق القائمة عند اللمس
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                header
                ScrollView { content }
                    .scrollIndicators(.hidden)
            }
            .frame(width: 226)
            .frame(maxHeight: 300)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 14, y: 6)
            .padding(.horizontal, 6)
            .padding(.top, 4)
        }
        .transition(.opacity)
    }

    // MARK: الترويسة

    private var header: some View {
        HStack(spacing: 6) {
            if page != .main {
                Button { page = .main } label: {
                    Image(systemName: "chevron.backward").font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.teal)
            }

            Text(title).font(.system(size: 12, weight: .bold, design: .rounded))

            Spacer()

            Button { onClose() } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
    }

    private var title: String {
        switch page {
        case .main:   return "القائمة"
        case .sets:   return "المجموعات"
        case .widget: return "إعدادات الودجت"
        }
    }

    // MARK: المحتوى

    @ViewBuilder
    private var content: some View {
        switch page {
        case .main:   mainPage
        case .sets:   setsPage
        case .widget: widgetPage
        }
    }

    // ── الصفحة الرئيسية ──

    private var mainPage: some View {
        VStack(spacing: 0) {

            sectionHeader("العرض")
            toggleRow("eye", "الرؤية من بعيد", model.distanceMode) { model.toggleDistanceMode() }
            toggleRow("text.book.closed", "وضع القراءة", model.readingMode) { model.toggleReadingMode() }

            segment("textformat.size", "حجم الخط",
                    ["ص", "م", "ك", "ض"],
                    selected: model.fontScaleIndex) { model.fontScaleIndex = $0; model.persistDisplay() }

            toggleRow("arrow.left.arrow.right", "العدّاد يمين الشاشة", model.badgeOnRight) {
                model.badgeOnRight.toggle(); model.persistDisplay()
            }

            toggleRow("photo", "خلفية المجموعة", model.backgroundOn) { model.toggleBackground() }

            segment("circle.lefthalf.filled", "شدّة الخلفية",
                    ["خافتة", "متوسطة", "واضحة"],
                    selected: model.backgroundLevel) { model.setBackgroundLevel($0) }

            divider

            // ── كيف تسجّل الذكر؟ أهم قسم لمن يسبّح ويده منخفضة ──
            sectionHeader("العدّ بلا نظر")
            segment("hand.point.up.left.fill", "طريقة العدّ",
                    CountingMode.allCases.map { $0.shortLabel },
                    selected: model.countingMode.rawValue) { i in
                model.setCountingMode(CountingMode(rawValue: i) ?? .doubleTap)
            }
            if model.countingMode == .motion {
                segment("waveform.path", "حساسية الحركة",
                        ["منخفضة", "متوسطة", "عالية"],
                        selected: model.motionSensitivityIndex) { model.setMotionSensitivity($0) }
            }
            // ملاحظة صريحة: النقرة المزدوجة لا تعمل والشاشة خافتة
            if model.countingMode == .doubleTap {
                noteRow("info.circle", "النقرة المزدوجة تحتاج شاشة مضيئة — اختر «حركة» أو «تاج» للعدّ والشاشة خافتة")
            }

            divider

            sectionHeader("التلقين")
            toggleRow("text.line.first.and.arrowtriangle.forward", "تمرير تلقائي", model.autoScroll) {
                model.toggleAutoScroll()
            }
            segment("speedometer", "الوتيرة",
                    ["هادئ", "متوسط", "سريع"],
                    selected: model.scrollSpeedIndex) { model.scrollSpeedIndex = $0; model.persistDisplay() }

            divider

            sectionHeader("المجموعات")
            navigationRow("square.grid.2x2", model.set.title) { page = .sets }

            divider

            sectionHeader("الودجت")
            navigationRow("square.grid.2x2.fill", widgetSummary) { page = .widget }

            divider

            sectionHeader("النظام")
            toggleRow("moon.fill", "الوضع الليلي", model.nightMode) { model.nightMode.toggle(); model.persistDisplay() }
            toggleRow("hand.tap.fill", "الاهتزاز", model.hapticsEnabled) { model.hapticsEnabled.toggle(); model.persistDisplay() }
            toggleRow("forward.fill", "الانتقال التلقائي", model.autoAdvance) { model.autoAdvance.toggle(); model.persistDisplay() }

            divider

            sectionHeader("الصوت والاهتزاز")
            toggleRow("speaker.wave.2.fill", "صوت نقرة ونغمة", model.soundEnabled) {
                model.soundEnabled.toggle(); model.persistDisplay()
                if model.soundEnabled { Sounds.play(.click) }     // ليسمع النتيجة فورًا
            }
            segment("waveform.path", "شدة الاهتزاز", ["ناعم", "متوسط", "قوي"],
                    selected: model.hapticLevelIndex) { i in
                model.hapticLevelIndex = i; model.persistDisplay()
                Haptics.tick()                                    // ليجرّب الشدّة فورًا
            }

            divider

            actionRow("arrow.counterclockwise", "تصفير الذكر", tint: .orange) { model.resetCurrent() }
            actionRow("flag.checkered", "إنهاء الجلسة", tint: .teal) { model.finishFreeSession() }

            // حالة الجلسة الممتدة
            HStack(spacing: 4) {
                Image(systemName: session.isActive ? "bolt.fill" : "bolt.slash")
                    .font(.system(size: 8))
                    .foregroundStyle(session.isActive ? .green : .orange)
                Text(session.statusText)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 9).padding(.vertical, 6)
        }
    }

    // ── صفحة المجموعات ──

    private var setsPage: some View {
        VStack(spacing: 0) {
            ForEach(Array(adhkarSets.enumerated()), id: \.element.id) { index, set in
                Button {
                    model.selectSet(index)
                    page = .main
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: set.symbol)
                            .font(.system(size: 10))
                            .foregroundStyle(index == model.s.setIndex ? .teal : .secondary)
                            .frame(width: 15)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(set.title).font(.system(size: 11, weight: .medium)).lineLimit(1)
                            Text(set.items.count.description + " أذكار").font(.system(size: 8)).foregroundStyle(.secondary)
                        }

                        Spacer()

                        if index == model.s.setIndex {
                            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.teal)
                        }
                    }
                    .padding(.horizontal, 9).padding(.vertical, 7)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // ── صفحة الودجت ──

    private var widgetPage: some View {
        VStack(spacing: 0) {

            segment("square.grid.2x2", "نمط الودجت",
                    ["الذكر الحالي", "ملخّص المجموعة"],
                    selected: model.widgetModeIndex) { model.setWidgetMode($0) }

            toggleRow("plus.circle", "زر تسجيل داخل الودجت", model.widgetShowsPlus) {
                model.widgetShowsPlus.toggle(); model.persistDisplay()
            }

            toggleRow("tag", "إظهار اسم المجموعة", model.widgetShowsSetName) {
                model.widgetShowsSetName.toggle(); model.persistDisplay()
            }

            Text("لا يمكن للتطبيق إضافة الودجت نيابةً عنك؛ النظام هو من يديره: اضغط مطوّلًا على وجه الساعة ← تحرير ← Smart Stack ← أضِف «سبحة». وهذه الإعدادات تتحكم في شكله وسلوكه بعد إضافته.")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 9).padding(.vertical, 7)
        }
    }

    // MARK: مكوّنات الصفوف

    /// سطر ملاحظة صغير (بلا تفاعل)
    private func noteRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: icon).font(.system(size: 9)).frame(width: 15).foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 8.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 9)
            .padding(.top, 8).padding(.bottom, 2)
    }

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.08)).frame(height: 1).padding(.vertical, 3)
    }

    private func toggleRow(_ icon: String, _ title: String, _ isOn: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 10)).frame(width: 15)
                    .foregroundStyle(isOn ? .teal : .secondary)
                Text(title).font(.system(size: 11)).lineLimit(1)
                Spacer()
                // مفتاح مصغّر بصريًا
                Capsule()
                    .fill(isOn ? Color.teal : Color.white.opacity(0.18))
                    .frame(width: 26, height: 15)
                    .overlay(
                        Circle().fill(.white)
                            .frame(width: 11, height: 11)
                            .offset(x: isOn ? -5.5 : 5.5)
                    )
            }
            .padding(.horizontal, 9).padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func navigationRow(_ icon: String, _ value: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 10)).frame(width: 15).foregroundStyle(.teal)
                Text(value).font(.system(size: 11)).lineLimit(1)
                Spacer()
                Image(systemName: "chevron.forward").font(.system(size: 9)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 9).padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func actionRow(_ icon: String, _ title: String, tint: Color,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 10)).frame(width: 15).foregroundStyle(tint)
                Text(title).font(.system(size: 11))
                Spacer()
            }
            .padding(.horizontal, 9).padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// شريط اختيار مقسّم (لحجم الخط والوتيرة والودجت)
    private func segment(_ icon: String, _ title: String, _ options: [String],
                         selected: Int, action: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 10)).frame(width: 15).foregroundStyle(.secondary)
                Text(title).font(.system(size: 11))
                Spacer()
            }
            .padding(.horizontal, 9)

            HStack(spacing: 3) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, label in
                    Button { action(i) } label: {
                        Text(label)
                            .font(.system(size: 9, weight: i == selected ? .semibold : .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(i == selected ? Color.teal.opacity(0.22) : Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(i == selected ? Color.teal.opacity(0.7) : .clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 9)
        }
        .padding(.vertical, 5)
    }

    private var widgetSummary: String {
        let mode = model.widgetModeIndex == 0 ? "الذكر الحالي" : "ملخّص المجموعة"
        return "\(mode) · \(model.widgetShowsPlus ? "بزر" : "بلا زر")"
    }
}
