//
//  SetBackgrounds.swift
//  سبحة — خلفيات خافتة متناسقة مع كل مجموعة أذكار
//
//  التصميم: لغة بصرية واحدة لكل المجموعات (فحمي/تركوازي داكن + توهّج هادئ)،
//  ويتغيّر الرمز فقط بحسب المجموعة — فتبقى الواجهة متّسقة ومريحة للعين.
//
//  الصور موجودة في مجلد الأصول: SetBackground_<id>
//  (كل صور بنسبة مربعة 312×312 و @2x = 624×624، ووزنها ~٤ ك.ب للصورة)
//

import SwiftUI

// MARK: - الربط بين المجموعة والخلفية

enum SetBackground {

    /// اسم الصورة في مجلد الأصول لكل معرّف مجموعة
    private static let map: [String: String] = [
        "after_prayer": "SetBackground_after_prayer",
        "morning":      "SetBackground_morning",
        "evening":      "SetBackground_evening",
        "sleep":        "SetBackground_sleep",
        "general":      "SetBackground_general",
        "free":         "SetBackground_free",
        // المجموعتان الجديدتان تعيدان استخدام خلفيتين من نفس العائلة البصرية
        // (التصميم لغة واحدة متّسقة — فلا نحتاج صورتين جديدتين)
        "istighfar":    "SetBackground_general",
        "salawat":      "SetBackground_evening"
    ]

    static func assetName(for set: DhikrSet) -> String? {
        map[set.id]
    }
}

// MARK: - طبقة الخلفية

/// تُوضع خلف محتوى الشاشة: صورة خافتة + تظليل مركزي كي يبقى النص مقروءًا.
struct SetBackgroundView: View {

    let setId: String
    var isOn: Bool
    var opacity: Double          // 0.35 خافتة · 0.55 متوسطة · 0.78 واضحة

    init(set: DhikrSet, isOn: Bool, opacity: Double) {
        self.setId  = set.id
        self.isOn   = isOn
        self.opacity = opacity
    }

    private var asset: String { "SetBackground_\(setId)" }

    var body: some View {
        ZStack {
            if isOn {
                // الصورة (تُرسم بحجم الشاشة كاملًا مع قصّ)
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .opacity(opacity)
                    .blur(radius: 0.3)                 // تنعيم خفيف جدًا: لا يشوّش النص
                    .ignoresSafeArea()

                // تظليل متدرّج: الشفافية وسط الشاشة حتى لا تُرهق العين، وعتمة عند الحواف
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.18),
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.78)
                    ]),
                    center: .center,
                    startRadius: 10,
                    endRadius: 170
                )
                .ignoresSafeArea()

                // تعتيم إضافي في الوضع الليلي
                Color.black.opacity(0.0)
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.6), value: isOn)   // تبديل ناعم للخلفية
        .animation(.easeInOut(duration: 0.6), value: setId)
        .allowsHitTesting(false)                              // لا تعترض اللمس ولا الإيماءة
    }
}

// MARK: - تعديل جاهز للاستخدام

extension View {

    /// يرسم خلفية المجموعة خلف أي واجهة
    func withSetBackground(_ set: DhikrSet,
                           isOn: Bool,
                           opacity: Double) -> some View {
        ZStack {
            Color.black
            SetBackgroundView(set: set, isOn: isOn, opacity: opacity)
            self
        }
    }
}
