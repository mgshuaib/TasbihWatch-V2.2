//
//  ReadingView.swift
//  سبحة — وضع القراءة: النص كاملًا + عدّاد صغير في الزاوية
//                 + تمرير تلقائي (تلقين) + رؤية من بعيد
//
//  ⭐ ملاحظة هندسية مهمة حول التلقين:
//  نستخدم هنا طبقة تعويض رأسية (offset) مع قصّ (clipped) بدل ScrollView،
//  لسببين:
//   1) حركة سلسة بمعدّل ثابت بالبكسل — لا يمكن تحقيقها بـ ScrollView.
//   2) أبل تنبّه أن ScrollView تجعل الضغط المزدوج **يمرّر** بدل تنفيذ الإجراء.
//      بدون ScrollView أثناء التلقين، تعمل الإيماءة على العدّاد بثقة كاملة.
//  وعند إيقاف التلقين نعود إلى ScrollView ليتمكن المستخدم من التمرير يدويًا.
//

import SwiftUI
import WatchKit

// MARK: - قياس ارتفاع النص (لحساب مسافة التمرير)

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - وضع القراءة

struct ReadingView: View {

    @ObservedObject var model: CounterModel
    /// تُمرَّر من الأعلى لتعطيل الإيماءة والقائمة مفتوحة
    var gestureEnabled: Bool = true

    @State private var y: CGFloat = 0            // موضع التلقين الحالي (بالنقاط)
    @State private var contentH: CGFloat = 0     // ارتفاع النص الكامل
    @State private var viewH: CGFloat = 0        // ارتفاع نافذة العرض
    @State private var reachedEnd = false
    @State private var nothingToScroll = false     // النص أقصر من الشاشة

    private let tickMS = 50                      // ٢٠ تحديثًا في الثانية

    var body: some View {
        VStack(spacing: 3) {
            if model.autoScroll {
                promptView                    // تلقين: حركة تلقائية سلسة
            } else {
                manualScrollView              // قراءة يدوية: تمرير بالإصبع
            }
        }
        // 📐 تملأ الطبقة كل المساحة المتبقية (الترويسة والتذييل ثابتان) — النص الطويل
        // يُمرَّر/يُقصّ داخل هذه الطبقة ولا يدفع الأزرار أو العدّاد خارج الشاشة أبدًا.
        .frame(maxHeight: .infinity, alignment: .top)
        // 🕐 العدّاد في الزاوية العلوية اليمنى (في RTL: .topLeading = اليمين)
        .overlay(alignment: model.badgeOnRight ? .topLeading : .topTrailing) {
            CounterBadge(model: model, gestureEnabled: gestureEnabled).padding(4)
        }
        // إعادة التلقين من أعلى عند تغيّر الذكر أو عند طلبه
        .onChange(of: model.current.id) { _, _ in resetPrompt() }
        .onChange(of: model.promptNonce) { _, _ in resetPrompt() }
        .task(id: promptTaskKey) { await runPrompt() }
    }

    /// أي تغيير هنا يعيد تشغيل حلقة التلقين
    private var promptTaskKey: String {
        "\(model.autoScroll)-\(model.promptPaused)-\(model.current.id)-\(model.promptNonce)-\(model.scrollSpeedIndex)"
    }

    // MARK: ① التلقين (تمرير تلقائي بوتيرة قراءة)

    private var promptView: some View {
        GeometryReader { geo in
            VStack(alignment: .trailing, spacing: 6) {
                dhikrTitle
                dhikrBody
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 62)                          // مساحة للعدّاد في الزاوية العلوية
            .padding(.bottom, 10)
            .padding(.horizontal, 2)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: ContentHeightKey.self, value: g.size.height)
                }
            )
            .offset(y: -y)
            .frame(maxHeight: .infinity, alignment: .top)
            .onAppear { viewH = geo.size.height }
            .onChange(of: geo.size.height) { _, h in viewH = h }
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { model.increment() }             // لمس أي مكان = ذكر
        .onPreferenceChange(ContentHeightKey.self) { contentH = $0 }
        .overlay(alignment: .top) {
            if reachedEnd { endOfTextHint }
        }
    }

    private var endOfTextHint: some View {
        Group {
            if nothingToScroll {
                // مثال النص القصير: رسالة صريحة بدل توقّف صامت يبدو كخلل
                Label("النص كامل على الشاشة — لا حاجة للتمرير", systemImage: "text.alignright")
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            } else {
                Button { resetPrompt() } label: {
                    Label("انتهى النص — إعادة", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    // MARK: ② القراءة اليدوية (ScrollView)

    private var manualScrollView: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 6) {
                dhikrTitle
                dhikrBody
            }
            .padding(.top, 62)                          // مساحة للعدّاد في الزاوية العلوية
            .padding(.bottom, 10)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(Rectangle())
            .onTapGesture { model.increment() }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: أجزاء النص

    private var dhikrTitle: some View {
        Text(model.current.text)
            .font(model.readingFont(size: 13 * model.effectiveFontScale))
            .fontWeight(.bold)
            .foregroundStyle(.teal)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var dhikrBody: some View {
        Text(model.current.full ?? model.current.text)
            .font(model.readingFont(size: 13.5 * model.effectiveFontScale))
            .fontWeight(model.readingWeight)             // أسمك = تشكيل أوضح
            .lineSpacing(model.readingLineSpacing)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: حلقة التلقين

    private var maxScroll: CGFloat { max(0, contentH - viewH) }

    /// بكسل/ثانية = (كل المسافة ÷ مدة القراءة المتوقعة بالكلمات)
    private var pointsPerSecond: CGFloat {
        guard maxScroll > 1 else { return 0 }
        let text = model.current.full ?? model.current.text
        let words = max(1, text.split(whereSeparator: { $0 == " " || $0 == "\n" }).count)
        let seconds = max(10.0, Double(words) * 60.0 / Double(model.wpm))   // وتيرة التلقين
        return maxScroll / CGFloat(seconds)
    }

    private func runPrompt() async {
        guard model.autoScroll, !model.promptPaused, !reachedEnd else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(tickMS))
            if Task.isCancelled { break }
            if !model.autoScroll || model.promptPaused || reachedEnd { break }
            advance()
        }
    }

    private func advance() {
        let maxY = maxScroll
        guard maxY > 1 else {                     // النص أقصر من الشاشة
            reachedEnd = true
            if !nothingToScroll {
                nothingToScroll = true
                model.promptNotice = "النص كامل على الشاشة — لا حاجة للتمرير"
                if model.hapticsEnabled { Haptics.play(.stop) }
            }
            return
        }
        y = min(y + pointsPerSecond * CGFloat(tickMS) / 1000.0, maxY)
        if y >= maxY - 1 {
            reachedEnd = true
            model.promptNotice = nil
            if model.hapticsEnabled { Haptics.play(.stop) }    // إشارة: انتهى التلقين
        }
    }

    private func resetPrompt() {
        y = 0
        reachedEnd = false
        nothingToScroll = false
        model.promptNotice = nil
        if model.hapticsEnabled { Haptics.tick() }
    }
}

// MARK: - العدّاد الصغير (الزاوية)

struct CounterBadge: View {

    @ObservedObject var model: CounterModel
    var gestureEnabled: Bool = true

    var body: some View {
        Button {
            model.increment()
        } label: {
            ZStack {
                Circle().fill(.ultraThinMaterial)
                Circle().stroke(.white.opacity(0.18), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: model.progress)
                    .stroke(model.isUnlimited ? Color.teal.opacity(0.5) : .teal,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.2), value: model.progress)

                VStack(spacing: -3) {
                    Text("\(model.s.count)")
                        .font(SabhaFont.numeral(17, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: model.s.count)

                    Text(model.isUnlimited ? "∞" : "\(model.current.target)")
                        .font(SabhaFont.ui(7, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 54, height: 54)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .primaryTapShortcut(enabled: gestureEnabled)   // ☝️🤏 الإيماءة تعمل هنا أيضًا
        .accessibilityLabel("عدّاد — \(model.s.count) من \(model.current.target)")
    }
}
