//
//  Haptics.swift
//  سبحة — طبقة الاهتزازات
//
//  أضِف هذا الملف إلى هدف التطبيق فقط.
//

import WatchKit

/// درجة الاهتزاز التي يختارها المستخدم (تُحفظ في الإعدادات)
enum HapticLevel: Int, CaseIterable {
    case soft = 0      // ناعم جدًا
    case medium = 1    // متوسط (الافتراضي)
    case strong = 2    // قوي

    var label: String { ["ناعم", "متوسط", "قوي"][rawValue] }
}

enum Haptics {

    static func play(_ type: WKHapticType) {
        // أبل تتجاهل الاهتزازات المتلاحقة السريعة؛ اهتزاز واحد لكل حدث.
        WKInterfaceDevice.current().play(type)
    }

    /// الدرجة المختارة من الإعدادات
    static var level: HapticLevel {
        HapticLevel(rawValue: SharedDefaults.store.object(forKey: SharedKeys.hapticLevel) as? Int ?? 1) ?? .medium
    }

    /// اهتزاز تسجيل الذكر بحسب الشدّة المختارة:
    ///   ناعم → click · متوسط → directionUp · قوي → notification
    static func tick() {
        switch level {
        case .soft:   play(.click)
        case .medium: play(.directionUp)
        case .strong: play(.notification)
        }
    }

    /// اكتمال ذكر واحد (٣٣ أو ١٠٠…) — يماثل الوصول لحبّة مميّزة في المسبحة.
    static func roundComplete() { play(.notification) }

    /// الانتقال إلى الذكر التالي — إشارة مختلفة تُشعر المستخدم بتغيّر الذكر بلا نظر.
    static func dhikrChanged() { play(.start) }

    /// 🎉 إتمام المجموعة كلها — إشارتان متعاقبتان لا تخطئهما الأذن.
    static func setCompleted() {
        play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { play(.success) }
    }

    /// تصفير.
    static func reset() { play(.stop) }
}
