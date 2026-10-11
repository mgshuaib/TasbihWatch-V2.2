//
//  CounterModel.swift
//  سبحة — جسر بين محرّك العدّ المشترك والواجهة
//
//  أضِف هذا الملف إلى هدف التطبيق فقط.
//

import Foundation
import SwiftUI

/// 🔢 كيف تسجّل الذكر؟ — النقرة المزدوجة لا تعمل والشاشة خافتة،
/// فحركة اليد والتاج بديلان يعملان في وضع السكون (أي وضع لليد).
/// (مُعلن خارج CounterModel حتى لا يرث عزل MainActor — فيُستخدم بلا قيود)
enum CountingMode: Int, CaseIterable, Identifiable {
    case doubleTap = 0, motion = 1, crown = 2

    var id: Int { rawValue }
    var shortLabel: String { ["نقرة", "حركة", "تاج"][safe] }
    var label: String { ["النقرة المزدوجة", "حركة اليد", "تدوير التاج"][safe] }
    var symbol: String { ["hand.tap.fill", "hand.wave.fill", "digitalcrown.arrow.clockwise"][safe] }
    /// هل تعمل والشاشة خافتة (وضع السكون)؟
    var worksWhenDim: Bool { self != .doubleTap }
    var hint: String {
        switch self {
        case .doubleTap: return "انقر بإصبعيك مرتين — تحتاج شاشة مضيئة (ارفع رسغك)"
        case .motion:    return "حرّك رسغك حركة صغيرة مقصودة لكل ذكر — تعمل والشاشة خافتة بإذن الله"
        case .crown:     return "دوّر التاج الرقمي للأعلى — كل نقرة ذكر"
        }
    }
    private var safe: Int { min(max(rawValue, 0), 2) }
}

@MainActor
final class CounterModel: ObservableObject {


    // MARK: - الحالة المنشورة

    @Published private(set) var s = SharedCounter.state()
    @Published private(set) var flashDhikr: String? = nil     // وميض «أكملت هذا الذكر»
    @Published private(set) var sessionStart = Date()
    @Published private(set) var summary: SessionSummary? = nil
    @Published var autoAdvance = true
    @Published var hapticsEnabled = true

    // ── تفضيلات العرض ──
    /// وضع القراءة: النص كامل في الشاشة + عدّاد صغير في الزاوية
    @Published var readingMode = false
    /// حجم الخط: 0 صغير · 1 متوسط · 2 كبير
    @Published var fontScaleIndex = 1
    // ── وضع العدّ: كيف يسجّل المستخدم الذكر؟ ──
    /// 0 النقرة المزدوجة (تحتاج شاشة مضيئة) · 1 حركة اليد (تعمل والشاشة خافتة) · 2 التاج
    @Published var countingMode: CountingMode = .doubleTap
    /// حساسية كشف الحركة: 0 منخفضة · 1 متوسطة · 2 عالية
    @Published var motionSensitivityIndex = 1 {
        didSet { motionCounter.sensitivity = MotionCounter.Sensitivity(rawValue: min(max(motionSensitivityIndex,0),2)) ?? .medium }
    }
    /// محرّك العدّ بالحركة (يُدار من العرض)
    let motionCounter = MotionCounter()

    /// موضع العدّاد الصغير: الزاوية العلوية اليمنى افتراضيًا (يُبدَّل لليسار من القائمة)
    @Published var badgeOnRight = true

    // ── التلقين (التمرير التلقائي) ──
    /// تمرير النص تلقائيًا بوتيرة قراءة
    @Published var autoScroll = false
    /// وتيرة التلقين: 0 هادئ 40 · 1 متوسط 60 · 2 سريع 90 (كلمة/دقيقة)
    @Published var scrollSpeedIndex = 1
    /// إيقاف مؤقت للتلقين (من زر التشغيل/الإيقاف)
    @Published var promptPaused = false

    // ── الرؤية من بعيد ──
    /// نص أكبر وأسمك + تباعد أسطر أوسع — لقراءة الليل ومن مسافة
    @Published var distanceMode = false
    /// خيار الخط: 0 نظام · 1 Amiri · 2 Scheherazade New
    @Published var fontFamilyIndex = 0
    /// الوضع الليلي (يُدار من القائمة المنسدلة)
    @Published var nightMode = false

    // ── الصوت والاهتزاز ──
    /// نقرة صوتية ناعمة + نغمة عند إتمام المجموعة (اختياري — من الإعدادات)
    @Published var soundEnabled = false
    /// شدة الاهتزاز: 0 ناعم · 1 متوسط · 2 قوي
    @Published var hapticLevelIndex = 1

    var hapticLevelLabel: String {
        HapticLevel(rawValue: min(max(hapticLevelIndex, 0), 2))?.label ?? "متوسط"
    }

    // ── خلفية المجموعة ──
    @Published var backgroundOn = true
    /// 0 خافتة · 1 متوسطة · 2 واضحة
    @Published var backgroundLevel = 1

    /// الشدّة الفعلية للخلفية
    var backgroundOpacity: Double { [0.35, 0.55, 0.78][min(max(backgroundLevel, 0), 2)] }
    var backgroundLevelLabel: String { ["خافتة", "متوسطة", "واضحة"][min(max(backgroundLevel, 0), 2)] }

    /// تصفير/تحديث خلفية المجموعة (تُستدعى بعد تغيير أي إعداد عرض)
    func setBackgroundLevel(_ level: Int) {
        backgroundLevel = min(max(level, 0), 2)
        showToast("شدّة الخلفية: \(backgroundLevelLabel)")
        save()
    }

    func toggleBackground() {
        backgroundOn.toggle()
        showToast(backgroundOn ? "خلفية المجموعة مفعّلة" : "خلفية المجموعة موقوفة")
        if hapticsEnabled { Haptics.tick() }
        save()
    }

    // ── إعدادات الودجت ──
    /// 0: الذكر الحالي · 1: ملخّص المجموعة
    @Published var widgetModeIndex = 0
    @Published var widgetShowsPlus = true
    @Published var widgetShowsSetName = true

    // ── الحسابات ──

    /// كلمات في الدقيقة لوتيرة التلقين
    var wpm: Int { [40, 60, 90][min(max(scrollSpeedIndex, 0), 2)] }
    var wpmLabel: String { ["هادئ ٤٠", "متوسط ٦٠", "سريع ٩٠"][min(max(scrollSpeedIndex, 0), 2)] }

    /// مضاعف حجم النص: صغير · متوسط · كبير · ضخم
    var fontScale: CGFloat { [0.9, 1.0, 1.15, 1.42][min(max(fontScaleIndex, 0), 3)] }
    var fontScaleLabel: String { ["صغير", "متوسط", "كبير", "ضخم"][min(max(fontScaleIndex, 0), 3)] }

    /// في «الرؤية من بعيد» نضمن أكبر حجم ممكن
    var effectiveFontScale: CGFloat { distanceMode ? max(fontScale, 1.42) : fontScale }
    var readingWeight: Font.Weight { distanceMode ? .bold : .regular }
    var readingLineSpacing: CGFloat { (distanceMode ? 7.5 : 4.0) * effectiveFontScale }

    /// خط القراءة: 0 خط النظام · 1 أميري (نسخي قرآنّي) · 2 المراعي (عصري)
    /// الخطوط **مرفقة داخل التطبيق** (مجلد Fonts) — وإن غابت لأي سبب يرجع خط النظام بسلاسة.
    var fontFamilyLabel: String {
        let labels = ["خط النظام", "أميري (نسخي)", "المراعي (عصري)"]
        let idx = min(max(fontFamilyIndex, 0), labels.count - 1)
        return idx != 0 && !SabhaFont.bundledFontsAvailable ? labels[idx] + " (غير مُضاف)" : labels[idx]
    }

    /// الخط الفعلي المستخدم في وضع القراءة
    func readingFont(size: CGFloat) -> Font {
        switch min(max(fontFamilyIndex, 0), 2) {
        case 1:  return SabhaFont.dhikr(size, bold: readingWeight == .bold)   // أميري
        case 2:  return SabhaFont.ui(size, weight: readingWeight)             // المراعي
        default: return .system(size: size, weight: readingWeight, design: .rounded)
        }
    }

    private let d = SharedDefaults.store

    var set: DhikrSet { SharedCounter.currentSet(s) }
    var current: Dhikr { SharedCounter.currentDhikr(s) }

    var isUnlimited: Bool { current.target <= 0 }
    var isSetDone: Bool { s.isSetDone }

    var progress: Double {
        guard current.target > 0 else { return 0 }
        return min(1, Double(s.count) / Double(current.target))
    }

    /// «الذكر ٣ من ٧»
    var positionText: String { "\(s.itemIndex + 1) / \(set.items.count)" }

    /// الذكر التالي (لعرضه كمعاينة تحضيرية للانتقال السلس)
    var nextDhikr: Dhikr? {
        guard s.itemIndex + 1 < set.items.count else { return nil }
        return set.items[s.itemIndex + 1]
    }

    // MARK: - التحميل

    init() {
        autoAdvance = d.object(forKey: SharedKeys.autoAdvance) as? Bool ?? true
        hapticsEnabled = d.object(forKey: SharedKeys.haptics) as? Bool ?? true
        readingMode = d.object(forKey: SharedKeys.readMode) as? Bool ?? false
        fontScaleIndex = d.object(forKey: SharedKeys.fontScale) as? Int ?? 1
        badgeOnRight = d.object(forKey: SharedKeys.badgeRight) as? Bool ?? true
        countingMode = CountingMode(rawValue: d.object(forKey: SharedKeys.countingMode) as? Int ?? 0) ?? .doubleTap
        motionSensitivityIndex = d.object(forKey: SharedKeys.motionSensitivity) as? Int ?? 1
        autoScroll = d.object(forKey: SharedKeys.autoScroll) as? Bool ?? false
        scrollSpeedIndex = d.object(forKey: SharedKeys.scrollSpeed) as? Int ?? 1
        distanceMode = d.object(forKey: SharedKeys.distanceMode) as? Bool ?? false
        // الخط المرفق (أميري) هو الافتراضي لوضع القراءة — نصّ الذكر يصير أجمل وأوضح
        fontFamilyIndex = d.object(forKey: SharedKeys.fontFamily) as? Int
            ?? (SabhaFont.bundledFontsAvailable ? 1 : 0)
        soundEnabled = d.object(forKey: SharedKeys.soundOn) as? Bool ?? false
        hapticLevelIndex = d.object(forKey: SharedKeys.hapticLevel) as? Int ?? 1
        nightMode = d.object(forKey: SharedKeys.nightMode) as? Bool ?? false
        backgroundOn = d.object(forKey: SharedKeys.bgOn) as? Bool ?? true
        backgroundLevel = d.object(forKey: SharedKeys.bgOpacity) as? Int ?? 1
        widgetModeIndex = d.object(forKey: SharedKeys.widgetMode) as? Int ?? 0
        widgetShowsPlus = d.object(forKey: SharedKeys.widgetShowsPlus) as? Bool ?? true
        widgetShowsSetName = d.object(forKey: SharedKeys.widgetShowsSet) as? Bool ?? true
        s = SharedCounter.state()
        if s.isSetDone { buildSummary() }
    }

    private func save() {
        d.set(autoAdvance, forKey: SharedKeys.autoAdvance)
        d.set(hapticsEnabled, forKey: SharedKeys.haptics)
        d.set(readingMode, forKey: SharedKeys.readMode)
        d.set(fontScaleIndex, forKey: SharedKeys.fontScale)
        d.set(badgeOnRight, forKey: SharedKeys.badgeRight)
        d.set(autoScroll, forKey: SharedKeys.autoScroll)
        d.set(scrollSpeedIndex, forKey: SharedKeys.scrollSpeed)
        d.set(distanceMode, forKey: SharedKeys.distanceMode)
        d.set(fontFamilyIndex, forKey: SharedKeys.fontFamily)
        d.set(soundEnabled, forKey: SharedKeys.soundOn)
        d.set(hapticLevelIndex, forKey: SharedKeys.hapticLevel)
        d.set(nightMode, forKey: SharedKeys.nightMode)
        d.set(backgroundOn, forKey: SharedKeys.bgOn)
        d.set(backgroundLevel, forKey: SharedKeys.bgOpacity)
        d.set(widgetModeIndex, forKey: SharedKeys.widgetMode)
        d.set(widgetShowsPlus, forKey: SharedKeys.widgetShowsPlus)
        d.set(widgetShowsSetName, forKey: SharedKeys.widgetShowsSet)
        d.set(countingMode.rawValue, forKey: SharedKeys.countingMode)
        d.set(motionSensitivityIndex, forKey: SharedKeys.motionSensitivity)
        WidgetBridge.reload()          // أي تغيير في إعدادات الودجت يحدّثه فورًا
    }

    /// يحفظ كل تفضيلات العرض (تستدعيها القائمة المنسدلة بعد كل تغيير)
    func persistDisplay() { save() }

    // MARK: - وضع العدّ (نقرة · حركة · تاج)

    /// يغيّر طريقة تسجيل الذكر، ويُشغّل/يوقف محرّك الحركة تلقائيًا.
    func setCountingMode(_ mode: CountingMode) {
        countingMode = mode
        if mode == .motion { startMotionCounting() } else { motionCounter.stop() }
        showToast(mode.label + " — " + (mode.worksWhenDim ? "تعمل والشاشة خافتة ✓" : "تحتاج شاشة مضيئة"))
        if hapticsEnabled { Haptics.tick() }
        save()
    }

    /// يبدأ كشف حركة الرسغ (يُستدعى من الواجهة عند ظهور العدّاد)
    func startMotionCounting() {
        guard countingMode == .motion else { return }
        guard motionCounter.isAvailable else {
            showToast("جهازك لا يدعم قراءة الحركة")
            return
        }
        motionCounter.sensitivity = MotionCounter.Sensitivity(rawValue: min(max(motionSensitivityIndex, 0), 2)) ?? .medium
        motionCounter.start()
    }

    func stopMotionCounting() { motionCounter.stop() }

    /// زيادة عدّ من كشف الحركة (بلا اهتزاز إضافي — الكاشف يهتزّ بنفسه)
    /// تُنادى من الواجهة عند تغيّر motionCounter.detected
    func tapFromMotion() {
        guard summary == nil, countingMode == .motion else { return }
        increment(silentHaptic: true)
    }

    func setMotionSensitivity(_ index: Int) {
        motionSensitivityIndex = min(max(index, 0), 2)
        showToast("حساسية الحركة: " + (MotionCounter.Sensitivity(rawValue: motionSensitivityIndex)?.label ?? "متوسطة"))
        if hapticsEnabled { Haptics.tick() }
        save()
    }

    /// سطر يشرح للمستخدم ماذا يفعل الآن — يظهر في وضع العدّ
    var countingHint: String { countingMode.hint }

    /// تغيير نمط الودجت
    func setWidgetMode(_ index: Int) {
        widgetModeIndex = min(max(index, 0), 1)
        showToast(widgetModeIndex == 0 ? "الودجت: الذكر الحالي" : "الودجت: ملخّص المجموعة")
        if hapticsEnabled { Haptics.tick() }
        save()
    }

    /// زر التلقين: يشغّل التلقين إن كان موقوفًا، وإلا يوقف/يستأنف.
    /// (سابقًا كان يبدّل الإيقاف المؤقت فقط، فبدا الزر «لا يعمل» لأن التلقين كان موقوفًا أصلًا)
    func togglePromptPause() {
        if !autoScroll {
            autoScroll = true
            promptPaused = false
            promptNonce += 1
            showToast("التلقين يعمل — \(wpmLabel) كلمة/دقيقة")
        } else if promptPaused {
            promptPaused = false
        } else {
            promptPaused = true
        }
        if hapticsEnabled { Haptics.tick() }
        save()
    }

    /// تبديل «الرؤية من بعيد» — يُشغّل وضع القراءة تلقائيًا لأنه خاص بالقراءة
    func toggleDistanceMode() {
        if !readingMode { readingMode = true; save() }
        distanceMode.toggle()
        showToast(distanceMode ? "الرؤية من بعيد: خط أكبر وأسمك" : "حجم العرض العادي")
        if hapticsEnabled { Haptics.tick() }
        save()
    }

    // ── رسائل داخل الشاشة (تغذية راجعة فورية) ──

    @Published var toastMessage: String? = nil
    private var toastTask: Task<Void, Never>?

    func showToast(_ text: String, seconds: Double = 2.4) {
        toastMessage = text
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled { self.toastMessage = nil }
        }
    }

    /// رسالة تُعرض في وضع القراءة عند عدم وجود ما يُمرَّر
    @Published var promptNotice: String? = nil

    /// إعادة التلقين من أعلى النص
    func restartPrompt() {
        promptPaused = false
        promptNonce += 1          // يُعلم الواجهة بإعادة التصفير
        if hapticsEnabled { Haptics.tick() }
    }

    /// يزداد عند طلب إعادة التلقين من أوله
    @Published var promptNonce = 0

    /// تشغيل/إيقاف التلقين كاملًا
    func toggleAutoScroll() {
        autoScroll.toggle()
        promptPaused = false
        if autoScroll { promptNonce += 1 }
        if hapticsEnabled { Haptics.tick() }
        save()
    }

    /// دورة حجم الخط: ٤ درجات
    func cycleFontScaleStep() {
        fontScaleIndex = (fontScaleIndex + 1) % 4
        save()
    }

    /// تبديل طريقة العرض: حلقة كبيرة ↔ قراءة النص كاملًا
    func toggleReadingMode() {
        readingMode.toggle()
        if hapticsEnabled { Haptics.tick() }
        save()
    }

    func cycleFontScale() { cycleFontScaleStep() }

    private func refresh() {
        s = SharedCounter.state()
        WidgetBridge.reload()
    }

    // MARK: - الضغطة ⭐

    /// زيادة العدّ. `silentHaptic` يُستخدم عند العدّ بالحركة لأن كاشف الحركة
    /// يُصدر الاهتزاز بنفسه لحظة الكشف (وإلا صار اهتزازان متتاليان لكل ذكر).
    func increment(silentHaptic: Bool = false) {
        guard !s.isSetDone else { return }

        let event = SharedCounter.tap()
        refresh()

        switch event {

        case .counted:
            if hapticsEnabled && !silentHaptic { Haptics.tick() }
            Sounds.play(.click)          // 🔊 نقرة ناعمة (إن كان الصوت مفعّلًا)

        case .advanced(let newIndex):
            // اكتمل الذكر: اهتزاز قوي + وميض قصير، ثم الانتقال السلس
            if hapticsEnabled { Haptics.roundComplete() }
            Sounds.play(.chime)          // 🔔 نغمة خفيفة عند إتمام الذكر
            let finishedName = set.items[max(0, newIndex - 1)].text
            withAnimation(.easeInOut(duration: 0.3)) { flashDhikr = finishedName }
            Task {
                try? await Task.sleep(for: .milliseconds(650))
                withAnimation(.easeInOut(duration: 0.35)) { flashDhikr = nil }
                if hapticsEnabled { Haptics.dhikrChanged() }
            }

        case .setCompleted:
            // 🎉 إتمام المجموعة: اهتزاز مزدوج مميّز + رسالة الإغلاق
            if hapticsEnabled { Haptics.setCompleted() }
            Sounds.play(.chime)          // 🔔 نغمة إتمام المجموعة
            buildSummary()
        }
    }

    // MARK: - أوامر

    func decrement() {
        guard !s.isSetDone else { return }
        SharedCounter.decrement()
        if hapticsEnabled { Haptics.tick() }
        refresh()
    }

    func resetCurrent() {
        // ثلاث حالات بتغذية راجعة واضحة — بدل الصمت الذي جعل الزر يبدو معطوبًا
        if s.isSetDone {
            summary = nil
            SharedCounter.resetCurrent()          // يُزيل حالة الإكمال أيضًا
            showToast("أُلغي الإكمال — يمكنك العدّ مجددًا")
        } else if s.count == 0 {
            showToast("العدد صفر بالفعل")
        } else {
            SharedCounter.resetCurrent()
            showToast("صُفِّر الذكر الحالي")
        }
        if hapticsEnabled { Haptics.reset() }
        refresh()
    }

    func restartSet() {
        SharedCounter.restartSet()
        if hapticsEnabled { Haptics.reset() }
        summary = nil
        sessionStart = Date()
        refresh()
    }

    func selectSet(_ index: Int) {
        SharedCounter.selectSet(index)
        summary = nil
        sessionStart = Date()
        if hapticsEnabled { Haptics.dhikrChanged() }
        refresh()
    }

    func closeSummary() {
        summary = nil
    }

    /// إنهاء «التسبيح المفتوح» بملخّص (لا يوجد عدد محدّد يُكمله)
    func finishFreeSession() {
        summary = SessionSummary(
            setTitle: set.title,
            dhikrCount: 1,
            totalTaps: s.count,
            duration: Date().timeIntervalSince(sessionStart),
            closeTitle: set.closeTitle,
            closeDua: set.closeDua
        )
        if hapticsEnabled { Haptics.setCompleted() }
    }

    // MARK: - ملخّص الجلسة (يظهر في رسالة الإغلاق)

    private func buildSummary() {
        summary = SessionSummary(
            setTitle: set.title,
            dhikrCount: set.items.count,
            totalTaps: set.items.reduce(0) { $0 + $1.target },
            duration: Date().timeIntervalSince(sessionStart),
            closeTitle: set.closeTitle,
            closeDua: set.closeDua
        )
    }
}

struct SessionSummary: Equatable {
    let setTitle: String
    let dhikrCount: Int
    let totalTaps: Int
    let duration: TimeInterval
    let closeTitle: String
    let closeDua: String

    var durationText: String {
        let m = Int(duration) / 60, sec = Int(duration) % 60
        if totalTaps == 0 { return "—" }
        return m > 0 ? "\(m) د \(sec) ث" : "\(sec) ثانية"
    }
}

// MARK: - إعادة تحميل ودجت Smart Stack

enum WidgetBridge {
    static func reload() {
        #if canImport(WidgetKit)
        Task { @MainActor in WidgetCenterProxy.reload() }
        #endif
    }
}

#if canImport(WidgetKit)
import WidgetKit
@MainActor
enum WidgetCenterProxy {
    static func reload() { WidgetCenter.shared.reloadAllTimelines() }
}
#endif
