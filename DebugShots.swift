//
//  DebugShots.swift
//  سبحة — مدخل لقطات المتجر (لا يعمل إلا في نسخة التطوير)
//
//  🎯 لماذا هذا الملف؟
//     أخذ لقطات حقيقية من محاكي ساعة أبل يحتاج فتح شاشات معيّنة، وسيرفر البناء
//     لا يستطيع النقر على شاشة الساعة. الحل: نمرّر اسم الشاشة مع أمر التشغيل:
//
//         xcrun simctl launch <device> <bundle> -sabhaScreen reading
//
//     فيقرأها التطبيق من UserDefaults (معاملات الإطلاق تصل إليها تلقائيًا).
//     هذا الملف يجهّز **الأرقام والذكر**، وكل ملف يعرض شاشته هو الذي يفتحها.
//
//  🔒 أمان نسخة المتجر:
//     كل هذا الملف محصور بين توجيهَي #if DEBUG و #endif ⇒ **يُحذف كليًا** من
//     نسخة المتجر (Release)، ولا يمكن أن يؤثر عليها. ويوجد فحص آلي (⑪ في
//     tests/swift-api-check.py) يمنع استعمال أي شيء منه خارج #if DEBUG.
//
//  الشاشات:  counter · reading · menu · stats · panel · onboarding
//

#if DEBUG
import Foundation

enum SabhaShot {

    /// اسم الشاشة المطلوبة (يأتي من معامل الإطلاق `-sabhaScreen <اسم>`).
    /// نقبل «counter» و«01-counter» معًا: السير يسمّي الملف بالرقم، والمستخدم
    /// قد يكتب الأمر يدويًا بلا رقم — فلا يهم أيّهما وصل.
    static var screen: String? {
        guard let raw = UserDefaults.standard.string(forKey: "sabhaScreen") else { return nil }
        return raw.contains("-") ? String(raw.split(separator: "-").last ?? "") : raw
    }

    static func isActive(_ name: String) -> Bool { screen == name }

    // MARK: - التهيئة (تعمل مرّة واحدة عند إقلاع التطبيق، قبل بناء الواجهة)

    /// تملأ الحالة: العدّ · الذكر الطويل · وإخفاء شاشة الترحيب
    static func prepareIfNeeded() {
        guard let screen else { return }

        // شاشة الترحيب لا تظهر داخل اللقطات (ولها لقطة خاصة تُطلب باسمها)
        UserDefaults.standard.set(true, forKey: SharedKeys.onboarded)

        switch screen {
        case "reading":
            moveToLongestDhikr()          // آية الكرسي: أطول نص كامل — أجمل لقطة للقراءة
        case "onboarding":
            break                         // بلا عدّ: اللقطة هي الشاشة نفسها
        default:
            seedCount(27)                 // ٢٧ من ٣٣ ⇒ الحلقة شبه مكتملة
        }
    }

    /// نعدّ ٢٧ ذكرًا بطريقة التطبيق الحقيقية (فيتعبّأ سجل الإحصاءات أيضًا).
    /// مرّة واحدة فقط: لو سُجّل اليوم ذكر واحد لا نُعيد العدّ عند كل تشغيل.
    static func seedCount(_ n: Int) {
        guard HistoryStore.today() == 0 else { return }
        for _ in 0..<n { _ = SharedCounter.tap() }
    }

    /// نتنقّل حتى نصل إلى ذكر له «نص كامل» طويل (آية الكرسي)
    static func moveToLongestDhikr() {
        for _ in 0..<60 {
            let s = SharedCounter.state()
            if let full = SharedCounter.currentDhikr(s).full, full.count >= 150 { return }
            let setIndex = s.setIndex
            let itemIndex = s.itemIndex
            _ = SharedCounter.skipToNext()
            let now = SharedCounter.state()
            if now.setIndex == setIndex && now.itemIndex == itemIndex { return }  // لا مزيد
        }
    }
}
#endif
