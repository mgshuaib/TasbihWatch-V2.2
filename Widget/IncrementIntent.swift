//
//  IncrementIntent.swift
//  سبحة — إجراء الودجت (App Intent)
//
//  أضِف هذا الملف إلى هدف الودجت (والتطبيق إن أردت استخدامه هناك أيضًا).
//
//  ⚠️ مهم: الودجت يقرأ من مجموعة التطبيق (App Group) عبر SharedCounter،
//  فالمنطق كله في الكود المشترك — لا تكرّره هنا.
//
//  🔧 إصلاح (سجل الإصلاحات): كان هذا الملف ينادي `SharedCounter.increment()`
//  وهي دالة **محذوفة** منذ إضافة نظام المجموعات ⇒ كان البناء يفشل بخطأ
//  «value of type 'SharedCounter' has no member 'increment'».
//  الصحيح الآن: `SharedCounter.tap()` التي تعيد StepEvent.
//

import AppIntents
import WidgetKit

struct IncrementDhikrIntent: AppIntent {

    static var title: LocalizedStringResource = "تسجيل ذكر"

    /// التشغيل بدون فتح التطبيق — هذا ما يجعل العدّ من الودجت فوريًا.
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        // ✅ يزيد العدد ويُدير الانتقال التلقائي للذكر التالي واكتمال المجموعة
        let event = SharedCounter.tap()

        // 🔊 لا يمكن تشغيل الاهتزاز من داخل إجراء الودجت دون فتح التطبيق،
        //    لكن يمكن تسجيل الحدث ليعرف التطبيق ما جرى عند فتحه.
        //    (الاهتزاز نفسه يعمل في عدّ داخل التطبيق عبر Haptics.play)
        switch event {
        case .counted:
            break
        case .advanced(let newIndex):
            SharedDefaults.store.set(newIndex, forKey: SharedKeys.lastAutoAdvanced)
        case .setCompleted:
            SharedDefaults.store.set(true, forKey: SharedKeys.lastSetCompleted)
        }

        // تحديث كل ودجات التطبيق فورًا (وإلا انتظرت دورة التحديث التالية)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
