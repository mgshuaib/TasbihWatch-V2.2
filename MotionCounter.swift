//
//  MotionCounter.swift
//  سبحة — العدّ بحركة اليد (التسبيح في أي وضع لليد)
//
//  🎯 لماذا هذا الملف؟
//  أبل لا تسمح بالنقرة المزدوجة ولا بالعدّ في وضع السكون: النقرة المزدوجة
//  **لا تعمل إلا والشاشة مضيئة** (رفع الرسغ)، ولا يوجد أي واجهة برمجية
//  (API) لتشغيل الشاشة برمجيًا. حركة «تقليب الرسغ» الجديدة في watchOS 26
//  محجوزة للنظام فقط ولا تُتاح للمطوّرين.
//
//  الحل الوحيد الباقي للعدّ والشاشة مطفأة: قراءة مستشعرات الحركة. التطبيق
//  يبقى حيًّا بجلسة تشغيل ممتدة (SessionManager)، وهذا الملف يقرأ
//  «حركة الجهاز المدمجة» (CMDeviceMotion) — وهي متاحة على الساعة منذ
//  watchOS 3 — فيحسب معدّل دوران الرسغ + تسارع اليد، ويكتشف «نكزة» مقصودة
//  (مثل تحريك السبابة/الرسغ كما يفعل المسبِّح) فيزيد العدّاد.
//
//  ⚠️ أمانة هندسية: هذا عدّاد حركة مخصّص، وليس إيماءة معتمدة من أبل:
//     • الحساسية تُضبط من القائمة (منخفضة/متوسطة/عالية) حسب قوة حركتك.
//     • كل عدّة تُصاحبها إشارة اهتزاز لتعرف أنها سُجّلت بلا نظر.
//     • قد يعدّ حركات غير مقصودة (مشي، سيارة) — لذلك هو وضع اختياري،
//       والعتبات مُتحكَّم بها، والحساسية المنخفضة هي الأكثر تحفّظًا.
//
//  الاستخدام (من الواجهة):
//     motion.sensitivity = .medium
//     motion.start()                    // يبدأ الكشف
//     .onChange(of: motion.detected) { model.increment() }   // كل نكزة = ذكر
//     motion.stop()
//
//  ملاحظة معمارية: هذا الصنف **غير معزول على MainActor** عن قصد — قراءات
//  CoreMotion تصل على طابور خلفي، وكل تحديث للواجهة/الاهتزاز يُنقل إلى
//  الطابور الرئيسي داخليًا (DispatchQueue.main.async). هذا يتجنّب أي مشكلة
//  في فحوصات التزامن (concurrency) عند الترجمة.
//

import Foundation
import CoreMotion
import WatchKit

final class MotionCounter: ObservableObject {

    /// حساسية الكشف — القيم الأعلى ⇒ عتبة أقل ⇒ يلتقط حركات أضعف
    enum Sensitivity: Int, CaseIterable, Identifiable {
        case low = 0, medium = 1, high = 2
        var id: Int { rawValue }
        var label: String { ["منخفضة", "متوسطة", "عالية"][safe] }

        /// عتبة «النكزة» (راد/ثانية + مساهمة التسارع)
        var threshold: Double { [2.30, 1.55, 1.05][safe] }
        /// أقل فاصل زمني بين عدّتين — يمنع عدّ الحركة الواحدة مرتين
        var refractory: TimeInterval { [0.80, 0.55, 0.38][safe] }
        private var safe: Int { min(max(rawValue, 0), 2) }
    }

    @Published private(set) var isRunning = false
    /// قيمة حيّة للعرض (نقطة تنبض مع كل حركة) — تُحدَّث على الطابور الرئيسي
    @Published private(set) var level: Double = 0
    /// 🔢 عدد النكزات المكتشفة — الواجهة تراقبه وتزيد العدّ عند كل تغيير
    @Published private(set) var detected: Int = 0

    var sensitivity: Sensitivity = .medium

    private let motion = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "tasbih.motion"
        q.qualityOfService = .userInitiated
        q.maxConcurrentOperationCount = 1
        return q
    }()
    private var lastFire = Date.distantPast
    private var armed = true              // لا يعدّ إلا بعد عودة الهدوء (hysteresis)

    // MARK: - التشغيل

    /// هل الجهاز يدعم قراءة حركة الجهاز؟ (متاح على Apple Watch منذ watchOS 3)
    var isAvailable: Bool { motion.isDeviceMotionAvailable }

    func start() {
        guard isAvailable, !isRunning else { return }

        motion.deviceMotionUpdateInterval = 1.0 / 25.0     // ٢٥ قراءة/ثانية — كافية وموفّرة
        motion.startDeviceMotionUpdates(to: queue) { [weak self] dm, _ in
            guard let self, let dm else { return }
            let mag = Self.magnitude(of: dm)               // حساب رياضي على الطابور الخلفي
            DispatchQueue.main.async { self.evaluate(mag) } // كل تغيير حالة على الرئيسي
        }
        isRunning = true
        level = 0
    }

    func stop() {
        guard isRunning else { return }
        motion.stopDeviceMotionUpdates()
        isRunning = false
        level = 0
        armed = true
    }

    func resetDetected() { detected = 0 }

    // MARK: - الخوارزمية

    /// قوة الحركة = مقدار معدّل الدوران + وزن للتسارع الخطّي
    private static func magnitude(of dm: CMDeviceMotion) -> Double {
        let w = dm.rotationRate
        let a = dm.userAcceleration
        let rate = (w.x * w.x + w.y * w.y + w.z * w.z).squareRoot()
        let accel = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
        return rate + accel * 5.0
    }

    /// تُنفَّذ على الطابور الرئيسي دائمًا
    private func evaluate(_ m: Double) {
        // مؤشر متحرّك ناعم للعرض
        level = level * 0.82 + m * 0.18

        let t = sensitivity.threshold
        let now = Date()

        if armed, m >= t, now.timeIntervalSince(lastFire) >= sensitivity.refractory {
            armed = false
            lastFire = now
            detected += 1
            WKInterfaceDevice.current().play(.click)     // تأكيد فوري بلا نظر
        } else if !armed, m < t * 0.6 {
            armed = true                                  // عاد الهدوء ⇒ استعدّ للنكزة التالية
        }
    }
}
