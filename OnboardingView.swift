//
//  OnboardingView.swift
//  سبحة — شاشة الترحيب والتعريف (تظهر مرّة واحدة، ويمكن إعادتها من القائمة)
//
//  🎯 أسلوب التطبيقات الحديثة: ثلاث صفحات قصيرة، رسم كبير، كلمة واحدة في العنوان،
//     ثم «ابدأ». لا نُثقل المستخدم بشرح تقني — فقط كيف يستخدم السبحة.
//

import SwiftUI

struct OnboardingView: View {

    /// عند الضغط على «ابدأ» أو «تخطّي»
    var onFinish: () -> Void

    @State private var page = 0

    private struct Page {
        let symbol: String
        let title: String
        let body: String
        let tint: Color
    }

    private let pages: [Page] = [
        Page(symbol: "hand.tap.fill",
             title: "سبّح بنقرة",
             body: "اضربْ إصبعك السبابة بالإبهام مرّتين لتسجيل ذكر. تعمل مع الشاشة المضيئة.",
             tint: SabhaColor.emerald),
        Page(symbol: "hand.wave.fill",
             title: "أو بحركة اليد",
             body: "حرّك يدك حركة خفيفة ليُسجَّل الذكر — تعمل حتى والشاشة خافتة. أو استخدم التاج.",
             tint: SabhaColor.teal),
        Page(symbol: "book.pages.fill",
             title: "اقرأ وتابع",
             body: "وضع القراءة يملأ الشاشة بالذكر كاملًا مع تلقين تلقائي، وإحصاءاتك في القائمة.",
             tint: SabhaColor.amber)
    ]

    var body: some View {
        VStack(spacing: 0) {

            // ───── زر التخطّي ─────
            HStack {
                Spacer()
                Button("تخطّي", action: onFinish)
                    .font(SabhaFont.ui(11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }
            .padding(.top, 4)

            Spacer(minLength: 4)

            // ───── الصفحة الحالية ─────
            let p = pages[page]

            ZStack {
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: [p.tint.opacity(0.45), .clear]),
                                         center: .center, startRadius: 2, endRadius: 62))
                    .frame(width: 118, height: 118)
                Image(systemName: p.symbol)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(p.tint)
                    .sabhaGlow(p.tint, radius: 18, opacity: 0.5)
            }
            .id(page)
            .transition(.scale(scale: 0.85).combined(with: .opacity))

            VStack(spacing: 6) {
                Text(p.title)
                    .font(SabhaFont.ui(19, weight: .bold))
                Text(p.body)
                    .font(SabhaFont.ui(12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 10)
            }
            .padding(.top, 10)

            Spacer(minLength: 4)

            // ───── النقاط ─────
            HStack(spacing: 5) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? SabhaColor.emerald : Color.white.opacity(0.20))
                        .frame(width: i == page ? 14 : 5, height: 5)
                        .animation(.snappy, value: page)
                }
            }
            .padding(.bottom, 10)

            // ───── الزر ─────
            Button {
                if page < pages.count - 1 {
                    withAnimation(.snappy) { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page < pages.count - 1 ? "التالي" : "ابدأ التسبيح")
                    .font(SabhaFont.ui(13, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LinearGradient(colors: [SabhaColor.emerald, SabhaColor.teal],
                                                 startPoint: .leading, endPoint: .trailing))
                    )
                    .foregroundStyle(SabhaColor.ink)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 8)
        .sabhaScreenBackground()
        .animation(.snappy, value: page)
    }
}
