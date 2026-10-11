//
//  SessionManager.swift
//  سبحة — جلسة التشغيل الممتدة (WKExtendedRuntimeSession)
//
//  🎯 المشكلة التي يحلّها هذا الملف:
//  عند تغيير وضع اليد، يُخفت watchOS الشاشة وينقل التطبيق إلى الخمول،
//  فيتوقف العدّ وتضيع الجلسة. استخدام «جلسة تشغيل ممتدة» يُعلم النظام
//  أن التطبيق مشغول بنشاط مقصود، فيستمر بالعمل مع الشاشة مطفأة:
//    • لا يُفقد العدّ
//    • تستمر الاهتزازات
//    • يبقى التطبيق في المقدمة، ويعود نشطًا فورًا بمجرد رفع الرسغ
//
//  ⚠️ شرط لا يعمل بدونه (سبب فشل 90% من المطوّرين):
//  يجب إضافة Background Modes في Info.plist لهدف تطبيق الساعة:
//
//      <key>WKBackgroundModes</key>
//      <array>
//          <string>self-care</string>   ← 10 دقائق كحد أقصى
//      </array>
//
//  لتشغيل جلسة أطول (حتى ساعة كاملة) استبدل القيمة بـ:
//          <string>mindfulness</string>
//
//  ملاحظة: تطبيق واحد = نوع واحد فقط من الجلسات (قاعدة من أبل).
//  إن لم تُضف المفتاح، سيفشل بدء الجلسة وسترى رسالة الخطأ على الشاشة.
//

import Foundation
import WatchKit
import SwiftUI

@MainActor
final class SessionManager: NSObject, ObservableObject {

    enum Phase: Equatable {
        case stopped
        case starting
        case active
        case expired
        case failed(String)
    }

    @Published private(set) var phase: Phase = .stopped
    @Published private(set) var expiresAt: Date?

    private var session: WKExtendedRuntimeSession?

    /// اكتب هنا القيمة التي أضفتها في WKBackgroundModes (للعرض فقط).
    /// ⬆️ نستخدم mindfulness (حتى ساعة كاملة) لأن العدّ قد يطول، وهي المناسبة
    ///    لأبعد نطاق زمني متاح لتطبيق ذكر/تأمّل. إن واجهت اعتراضًا في المراجعة
    ///    أو أردت جلسة أقصر، أعد القيمة إلى "self-care" (10 دقائق) في:
    ///      ① project.yml → WKBackgroundModes
    ///      ② هذه السلسلة
    static let typeDescription = "mindfulness (حتى ساعة) — تُبقي العدّ حيًّا والشاشة مطفأة"

    // MARK: - التحكم

    /// استدعِها عند فتح الشاشة، وعند رفع الرسغ/العودة للتطبيق.
    func start() {
        // لا تُكرّر الجلسة إن كانت قائمة
        if let s = session {
            switch s.state {
            case .running, .scheduled: return
            default: break
            }
        }

        let s = WKExtendedRuntimeSession()
        s.delegate = self
        session = s

        phase = .starting
        // يعمل البدء فقط والتطبيق في المقدمة
        s.start()
    }

    func stop() {
        session?.invalidate()
        session = nil
        expiresAt = nil
        phase = .stopped
    }

    // MARK: - نص الحالة للعرض

    var statusText: String {
        switch phase {
        case .stopped:
            return "الجلسة متوقفة"
        case .starting:
            return "جارٍ تشغيل الجلسة…"
        case .active:
            if let d = expiresAt {
                let f = DateFormatter()
                f.locale = Locale(identifier: "ar")
                f.dateFormat = "h:mm"
                return "العدّ يستمر حتى \(f.string(from: d))"
            }
            return "العدّ مستمر"
        case .expired:
            return "انتهت المدة — ارفع رسغك للتجديد"
        case .failed(let msg):
            return "تعذّر بدء الجلسة: \(msg)"
        }
    }

    var isActive: Bool { phase == .active }
    var isProblem: Bool {
        if case .failed = phase { return true }
        return false
    }
}

// MARK: - WKExtendedRuntimeSessionDelegate

extension SessionManager: WKExtendedRuntimeSessionDelegate {

    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            self.phase = .active
            self.expiresAt = extendedRuntimeSession.expirationDate
        }
    }

    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            self.phase = .expired
            // تنبيه ملموس قبل انتهاء المدة — مستخدم لا ينظر للشاشة
            Haptics.play(.retry)
        }
    }

    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: (any Error)?
    ) {
        Task { @MainActor in
            self.session = nil
            self.expiresAt = nil
            if let error {
                // أشهر سبب: WKBackgroundModes غير مضاف في Info.plist
                self.phase = .failed(error.localizedDescription)
            } else {
                self.phase = .stopped
            }
        }
    }
}
