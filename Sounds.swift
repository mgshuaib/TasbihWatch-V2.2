//
//  Sounds.swift
//  سبحة — الأصوات الناعمة + درجات الاهتزاز
//
//  🎧 لماذا صوت في تطبيق تسبيح؟
//     السبحة الحقيقية لها صوت خفيف للنقرة. النقرة الصوتية الناعمة تعطي
//     إحساسًا مألوفًا (وتفيد من لا يشعر بالاهتزاز جيدًا)، ومعها نغمة خفيفة
//     عند إتمام المجموعة. كلاهما **اختياري** من الإعدادات.
//
//  ⚠️ بصراحة عن قيود watchOS:
//     • الصوت يعمل عندما يكون التطبيق في المقدمة (شاشتك مضيئة أو حديثة الرفع).
//     • إذا كان الصوت مكتومًا من الإعدادات أو التطبيق في الخلفية → نرجع
//       تلقائيًا إلى الاهتزاز فقط، ولا يحدث أي خطأ.
//     • الجلسات الطويلة: لا نُشغّل أي جلسة صوت من الخلفية (لا تسمح أبل بذلك).
//

import Foundation

#if canImport(AVFoundation)
import AVFoundation
#endif

enum SabhaSound: String {
    case click = "click_soft"     // نقرة السبحة
    case chime = "chime_soft"     // نغمة إتمام المجموعة
}

enum Sounds {

    // MARK: الإعدادات

    /// الصوت مفعّل؟ (يقرأه التطبيق من الإعدادات)
    static var isEnabled: Bool {
        SharedDefaults.store.object(forKey: SharedKeys.soundOn) as? Bool ?? false
    }

    static func setEnabled(_ on: Bool) {
        SharedDefaults.store.set(on, forKey: SharedKeys.soundOn)
    }

    // MARK: التشغيل

    #if canImport(AVFoundation)
    /// مشغّلات محفوظة: تحميل الملف مرّة واحدة ثم إعادة تشغيله = بلا تأخير في اللمس
    private static var players: [String: AVAudioPlayer] = [:]
    #endif

    /// يشغّل صوتًا ناعمًا. إن لم يتوفر الصوت لأي سبب: يهتزّ اهتزازًا عاديًا بدلًا منه.
    static func play(_ sound: SabhaSound) {
        guard isEnabled else { return }

        #if canImport(AVFoundation)
        if let player = player(for: sound) {
            player.currentTime = 0
            if player.play() { return }
        }
        #endif

        // احتياطي: لو تعذّر الصوت، لا نترك المستخدم بلا إحساس — اهتزاز خفيف
        if sound == .click { Haptics.play(.click) } else { Haptics.play(.success) }
    }

    #if canImport(AVFoundation)
    private static func player(for sound: SabhaSound) -> AVAudioPlayer? {
        if let p = players[sound.rawValue] { return p }

        // نبحث عن الملف في جذر الحزمة أو داخل مجلد Sounds (يعمل في الحالتين)
        let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav")
               ?? Bundle.main.url(forResource: sound.rawValue, withExtension: "wav", subdirectory: "Sounds")
        guard let url, let p = try? AVAudioPlayer(contentsOf: url) else { return nil }

        p.volume = sound == .click ? 0.35 : 0.50     // ناعم عن قصد
        p.prepareToPlay()
        players[sound.rawValue] = p
        return p
    }
    #endif
}
