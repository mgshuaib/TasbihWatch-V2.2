//
//  Theme.swift
//  سبحة — نظام التصميم الموحّد (الألوان · الخطوط · المسافات · المكوّنات)
//
//  🎯 لماذا هذا الملف؟
//     حتى تبقى الواجهة كلها «لغة بصرية واحدة» مثل التطبيقات الحديثة:
//     نفس العائلة اللونية، نفس أزرار «الزجاج»، نفس الإيقاع في الخطوط والمسافات.
//     أي تعديل مستقبلي في اللون أو الخط يحدث من هنا فقط — لا من كل شاشة.
//

import SwiftUI

// ⚠️ درس من فحص الترجمة: الملف الذي يستعمل `UIFont` يجب أن يُعلن استيراد UIKit
//    بنفسه — لا نعتمد على ملف آخر في نفس الهدف. (UIFont متاح على watchOS)
#if canImport(UIKit)
import UIKit
#endif

// MARK: - الألوان

enum SabhaColor {

    /// اللون الأساسي: أخضر زمردي هادئ (لون التسبيح في الثقافة الإسلامية)
    static let emerald = Color(red: 0.16, green: 0.78, blue: 0.60)
    /// اللون الثاني: فيروزي عميق
    static let teal    = Color(red: 0.20, green: 0.62, blue: 0.72)
    /// اللون الثالث: ذهبي فاتح (للمسات واللمعات فقط)
    static let amber   = Color(red: 0.98, green: 0.78, blue: 0.40)
    /// لون النجاح (إتمام مجموعة)
    static let mint    = Color(red: 0.35, green: 0.88, blue: 0.68)

    /// خلفية الشاشة الأساسية (فحمي مزرق هادئ — لا أسود صارخ)
    static let ink     = Color(red: 0.043, green: 0.063, blue: 0.078)
    /// سطح البطاقات
    static let surface = Color.white.opacity(0.06)
    /// حدود البطاقات
    static let stroke  = Color.white.opacity(0.10)
}

// MARK: - التدرجات

enum SabhaGradient {

    /// تدرّج الحلقة الكبيرة (زمردي ← فيروزي)
    static let ring = AngularGradient(
        gradient: Gradient(colors: [SabhaColor.emerald, SabhaColor.mint, SabhaColor.teal, SabhaColor.emerald]),
        center: .center
    )

    /// توهّج خلف الحلقة يعطي عمقًا (مثل الواجهات الحديثة)
    static let glow = RadialGradient(
        gradient: Gradient(colors: [SabhaColor.emerald.opacity(0.35), .clear]),
        center: .center, startRadius: 4, endRadius: 96
    )

    /// تدرّج البطاقة
    static let card = LinearGradient(
        gradient: Gradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.03)]),
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// شريط التقدّم في شاشة الإحصاءات
    static let bar = LinearGradient(
        gradient: Gradient(colors: [SabhaColor.emerald, SabhaColor.teal]),
        startPoint: .bottom, endPoint: .top
    )
}

// MARK: - الخطوط

enum SabhaFont {

    /// أسماء الخطوط المرفقة (مطابقة لِـ PostScript name داخل ملف الخط)
    static let dhikrFontNames  = ["Amiri-Regular", "Amiri-Bold"]        // أميري: نسخي قرآنّي
    static let uiFontNames     = ["Almarai-Regular", "Almarai-Bold"]    // المراعي: عصري نظيف للأرقام والواجهة

    /// هل الخط مرفق فعلًا في الحزمة؟ (فلا نطلب من النظام خطًا غير موجود)
    private static func available(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIFont(name: name, size: 12) != nil
        #else
        return false
        #endif
    }

    /// خط نصوص الأذكار: أميري (نسخي) إن كان مرفقًا، وإلا خط النظام بسلاسة.
    static func dhikr(_ size: CGFloat, bold: Bool = false) -> Font {
        let name = bold ? dhikrFontNames[1] : dhikrFontNames[0]
        return available(name) ? .custom(name, size: size)
                               : .system(size: size, weight: bold ? .bold : .regular, design: .serif)
    }

    /// خط الواجهة العربية (العناوين والوسوم): المراعي إن كان مرفقًا.
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // ملاحظة: وزن الخط في SwiftUI يقبل == فقط (لا يقبل >=) — نسأل عن الأوزان الثقيلة مباشرة.
        let isHeavy = [Font.Weight.semibold, .bold, .heavy, .black].contains(weight)
        let name = isHeavy ? uiFontNames[1] : uiFontNames[0]
        return available(name) ? .custom(name, size: size)
                               : .system(size: size, weight: weight, design: .rounded)
    }

    /// الأرقام تبقى بخط النظام (أوضح وأدقّ في العدّ) مع أرقام ثابتة العرض.
    static func numeral(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    /// هل الخطوط المرفقة متاحة في هذه النسخة من التطبيق؟ (تعرضه الإعدادات)
    static var bundledFontsAvailable: Bool { available(dhikrFontNames[0]) && available(uiFontNames[0]) }
}

// MARK: - المقاسات والإيقاع

enum SabhaMetric {
    static let cardRadius: CGFloat  = 14
    static let cardPadding: CGFloat = 10
    static let gap: CGFloat         = 6
    static let ringSize: CGFloat    = 128
    static let ringWidth: CGFloat   = 9
}

// MARK: - مكوّنات جاهزة

extension View {

    /// بطاقة «زجاجية» موحّدة لكل الشاشات
    func sabhaCard(padding: CGFloat = SabhaMetric.cardPadding) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: SabhaMetric.cardRadius, style: .continuous)
                    .fill(SabhaGradient.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: SabhaMetric.cardRadius, style: .continuous)
                            .stroke(SabhaColor.stroke, lineWidth: 0.8)
                    )
            )
    }

    /// ظل ملوّن ناعم (توهّج) — يعطي إحساس العمق في الواجهات الحديثة
    func sabhaGlow(_ color: Color = SabhaColor.emerald, radius: CGFloat = 14, opacity: Double = 0.35) -> some View {
        self.shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
    }

    /// خلفية الشاشة الأساسية الموحّدة (تدرّج هادئ بدل الأسود المسطّح)
    func sabhaScreenBackground() -> some View {
        self.background(
            ZStack {
                SabhaColor.ink
                RadialGradient(gradient: Gradient(colors: [SabhaColor.teal.opacity(0.16), .clear]),
                               center: .top, startRadius: 2, endRadius: 220)
            }
            .ignoresSafeArea()
        )
    }
}

/// «شرارة» معلومات صغيرة: أيقونة + نص، بخلفية زجاجية — تُستخدم في الترويسة والبطاقات
struct SabhaChip: View {
    let symbol: String
    let text: String
    var tint: Color = SabhaColor.emerald

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 9, weight: .semibold))
            Text(text).font(SabhaFont.ui(10, weight: .semibold)).lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Capsule().fill(tint.opacity(0.14)))
        .overlay(Capsule().stroke(tint.opacity(0.28), lineWidth: 0.7))
    }
}
