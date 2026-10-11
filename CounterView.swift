//
//  CounterView.swift
//  سبحة — شاشة العدّ
//
//  أوضاع العرض:
//  ① حلقة كبيرة (افتراضي) — عدد ضخم واضح من نظرة واحدة.
//  ② وضع القراءة — النص الكامل للذكر يملأ الشاشة، والعدّاد صغير في الزاوية. ⭐
//

import SwiftUI

struct CounterView: View {

    @StateObject private var model = CounterModel()
    @StateObject private var session = SessionManager()

    @State private var showMenu = false
    /// شاشة الترحيب: تظهر مرّة واحدة، ويمكن إعادتها من القائمة
    @AppStorage(SharedKeys.onboarded) private var onboarded = false
    @State private var showOnboarding = false
    @State private var showPanel = false        // ☰ القائمة المنسدلة في الزاوية اليسرى
    @State private var showFullText = false

    @Environment(\.isLuminanceReduced) private var luminanceReduced
    @Environment(\.scenePhase) private var scenePhase

    // ── العدّ بحركة اليد (يعمل والشاشة خافتة) ──
    @StateObject private var motion = MotionCounter()

    // ── العدّ بالتاج: نحسب «نقرات» التاج تجاه الأعلى فقط ──
    @State private var crownOffset: Double = 0
    @State private var crownLastTick: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // 🎨 خلفية أساسية موحّدة (فحمي مزرق + توهّج علوي) — تُبنى فوقها صورة المجموعة
                SabhaColor.ink.ignoresSafeArea()
                RadialGradient(gradient: Gradient(colors: [SabhaColor.teal.opacity(0.18), .clear]),
                               center: .top, startRadius: 4, endRadius: 240)
                    .ignoresSafeArea()

                // 🖼️ خلفية المجموعة (خافتة، متناسقة، وتتبدّل مع كل مجموعة)
                SetBackgroundView(set: model.set,
                                  isOn: model.backgroundOn && !showPanel,
                                  opacity: model.backgroundOpacity)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    if model.readingMode {
                        readingLayout
                    } else {
                        ringLayout
                    }
                    if !luminanceReduced { footer }
                }
                .padding(.horizontal, model.readingMode ? 8 : 10)

                // 🌙 وضع السكون (الشاشة خافتة): عرض مبسّط بخط كبير يُقرأ بنظرة
                if luminanceReduced && !showPanel { aodLiteView }

                // 👋 شاشة الترحيب (أول تشغيل، أو عند طلبها من القائمة)
                if (!onboarded || showOnboarding) && !showPanel {
                    OnboardingView {
                        onboarded = true
                        withAnimation(.easeOut(duration: 0.25)) { showOnboarding = false }
                    }
                    .zIndex(3)
                }

                if let flash = model.flashDhikr { flashOverlay(flash) }

                // 🔔 تغذية راجعة فورية لأزرار التصفير والتلقين والرؤية من بعيد
                if let toast = model.toastMessage {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(SabhaFont.ui(10, weight: .semibold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.black.opacity(0.82), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
                            .padding(.bottom, 6)
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.2), value: model.toastMessage)
                }

                // ☰ القائمة المنسدلة — غير معطّلة لأي تفاعل في الأعلى
                if showPanel {
                    OptionsPanel(model: model, session: session) {
                        withAnimation(.easeInOut(duration: 0.15)) { showPanel = false }
                    }
                }

                if let summary = model.summary {
                    CompletionView(summary: summary,
                                   onRestart: { model.restartSet() },
                                   onChooseSet: { model.closeSummary(); showMenu = true },
                                   onClose: { model.closeSummary() })
                        .transition(.opacity)
                }
            }
            .opacity(model.nightMode && !showPanel ? 0.4 : 1)
            .animation(.easeInOut(duration: 0.25), value: model.nightMode)
            .toolbar {
                if !luminanceReduced && model.summary == nil {
                    // ☰ في الزاوية العلوية اليسرى
                    // (في RTL يكون .topBarTrailing هو اليسار فعليًا)
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { withAnimation(.easeOut(duration: 0.15)) { showPanel.toggle() } } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(showPanel ? .teal : .white)
                        }
                        .accessibilityLabel("القائمة والإعدادات")
                    }

                    if model.readingMode {
                        // 👁️ الرؤية من بعيد — في أعلى الشاشة مع التلقين (كان أسفلها)
                        ToolbarItem(placement: .topBarLeading) {
                            Button { model.toggleDistanceMode() } label: {
                                Image(systemName: model.distanceMode ? "eye.fill" : "eye")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(model.distanceMode ? .teal : .secondary)
                            }
                            .accessibilityLabel(model.distanceMode ? "إيقاف الرؤية من بعيد" : "تشغيل الرؤية من بعيد")
                        }

                        // ⏯ زر التلقين — لا يستهلك الإجراء الرئيسي (الإيماءة للعدّاد)
                        ToolbarItem(placement: .topBarLeading) {
                            Button { model.togglePromptPause() } label: {
                                Image(systemName: model.autoScroll
                                      ? (model.promptPaused ? "play.fill" : "pause.fill")
                                      : "text.line.first.and.arrowtriangle.forward")
                                    .font(.system(size: 12))
                                    .foregroundStyle(model.autoScroll ? .teal : .secondary)
                            }
                            .accessibilityLabel(model.autoScroll ? "تشغيل/إيقاف التلقين" : "التلقين موقوف")
                        }
                    } else if model.current.full != nil {
                        ToolbarItem(placement: .topBarLeading) {
                            Button { showFullText = true } label: { Image(systemName: "book") }
                        }
                    }
                }
            }
            .sheet(isPresented: $showMenu) {
                MenuView(nightMode: $model.nightMode, showOnboarding: $showOnboarding)
                    .environmentObject(model)
                    .environmentObject(session)
            }
            .sheet(isPresented: $showFullText) {
                FullTextView(dhikr: model.current)
            }
        }
        .onAppear {
            session.start()
            if model.countingMode == .motion { model.startMotionCounting() }
        }
        .onChange(of: model.countingMode) { _, mode in
            if mode == .motion { model.startMotionCounting() } else { model.stopMotionCounting() }
        }
        .onChange(of: scenePhase) { _, phase in
            // أوقف المستشعر في الخلفية لتوفير البطارية، وأعد تشغيله عند العودة
            if phase == .active { if model.countingMode == .motion { model.startMotionCounting() } }
            else if phase == .background { model.stopMotionCounting() }
        }
        // 🎡 العدّ بالتاج: التركيز + قراءة الدوران (يعمل في وضع السكون بعد إيقاظ الشاشة بالتاج)
        .focusable(model.countingMode == .crown)
        // 🎡 المُحمّل الأبسط والأكثر توافقًا (بلا onChange/onIdle) — العدّ عبر onChange أدناه
        .digitalCrownRotation(
            $crownOffset,
            from: 0, through: 1_000_000, by: 1,
            sensitivity: .medium,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownOffset) { _, _ in crownTickIfNeeded() }
        // ✋ كل نكزة يكتشفها المستشعر = ذكر واحد
        .onChange(of: motion.detected) { _, _ in model.tapFromMotion() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { session.start() } }
    }

    // MARK: - الترويسة (مع زر تبديل طريقة العرض)

    private var header: some View {
        VStack(spacing: 2) {
            HStack(spacing: 5) {
                // زر تبديل طريقة العرض: حلقة كبيرة ↔ نص كامل
                Button {
                    model.toggleReadingMode()
                } label: {
                    Image(systemName: model.readingMode ? "circle.dashed" : "text.alignright")
                        .font(.system(size: 11))
                        .foregroundStyle(.teal)
                }
                .buttonStyle(.plain)
                .secondaryTapShortcut()
                .accessibilityLabel(model.readingMode ? "العرض بحلقة كبيرة" : "عرض النص كاملًا")

                SabhaChip(symbol: model.set.symbol, text: model.set.title, tint: SabhaColor.teal)

                Spacer(minLength: 2)

                Text(model.positionText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            // في الوضع العادي: اسم الذكر هنا. في وضع القراءة: يظهر داخل النص نفسه.
            if !model.readingMode {
                Text(model.current.text)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .id(model.current.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal:   .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.35), value: model.current.id)
            }
        }
        .padding(.top, 2)
        .frame(height: 54, alignment: .top)      // 📐 ارتفاع ثابت: لا تحرّك للأزرار
    }

    // MARK: - 🎡 العدّ بالتاج

    /// كل «نقرة» تاج تجاه الأعلى = ذكر واحد. لا نُنقص عند الدوران للأسفل.
    private func crownTickIfNeeded() {
        guard model.countingMode == .crown, !showPanel, model.summary == nil else {
            crownLastTick = crownOffset; return
        }
        let steps = Int(crownOffset.rounded()) - Int(crownLastTick.rounded())
        crownLastTick = crownOffset
        guard steps > 0 else { return }
        for _ in 0..<min(steps, 6) { model.increment() }      // حدّ أقصى لكل دفعة
    }

    // MARK: - 🌙 شاشة وضع السكون (مبسّطة، خط كبير، بلا عناصر كثيرة)

    private var aodLiteView: some View {
        VStack(spacing: 2) {
            Text("\(model.s.count)")
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(model.isUnlimited ? "بلا حد" : "من \(model.current.target)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: model.countingMode.symbol).font(.system(size: 9))
                Text(model.countingMode.worksWhenDim ? "العدّ بال\(model.countingMode.shortLabel) يعمل الآن"
                                                     : "ارفع رسغك ثم انقر مرتين")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
            }
            .foregroundStyle(model.countingMode.worksWhenDim ? Color.teal : Color.secondary)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)          // خلفية سوداء = أوفر للشاشة الخافتة
        .overlay(alignment: .bottomTrailing) {
            // مؤشر حيّ لكشف الحركة: يومض مع كل حركة مكتشفة
            if model.countingMode == .motion {
                Circle()
                    .fill(Color.teal.opacity(motion.level > 0.35 ? 0.9 : 0.25))
                    .frame(width: 6, height: 6)
                    .padding(10)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - ① الحلقة الكبيرة

    private var ringLayout: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 2)

            Button {
                model.increment()
            } label: {
                ZStack {
                    // توهّج خلف الحلقة — يعطي إحساس العمق في الواجهات الحديثة
                    Circle().fill(SabhaGradient.glow)
                        .frame(width: 148, height: 148)
                        .blur(radius: 6)

                    // المسار الخلفي
                    Circle().stroke(Color.white.opacity(0.10), lineWidth: SabhaMetric.ringWidth)

                    // التقدّم: تدرّج زمردي ← فيروزي
                    Circle()
                        .trim(from: 0, to: model.progress)
                        .stroke(SabhaGradient.ring,
                                style: StrokeStyle(lineWidth: SabhaMetric.ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.25), value: model.progress)
                        .sabhaGlow(radius: 10, opacity: 0.40)

                    VStack(spacing: -2) {
                        Text("\(model.s.count)")
                            .font(SabhaFont.numeral(62, weight: .semibold))
                            .contentTransition(.numericText())
                            .animation(.snappy, value: model.s.count)
                        Text(model.isUnlimited ? "بلا حد" : "/ \(model.current.target)")
                            .font(SabhaFont.ui(11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: SabhaMetric.ringSize, height: SabhaMetric.ringSize)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .primaryTapShortcut(enabled: !showPanel && model.summary == nil && !(!onboarded || showOnboarding))

            Spacer(minLength: 2)
        }
    }

    // MARK: - ② وضع القراءة (نص كامل + عدّاد في الزاوية + تلقين)

    private var readingLayout: some View {
        ReadingView(model: model, gestureEnabled: !showPanel && model.summary == nil)
    }

    // MARK: - التذييل

    private var footer: some View {
        VStack(spacing: 4) {
            // شريط تقدّم المجموعة
            HStack(spacing: 3) {
                ForEach(Array(model.set.items.enumerated()), id: \.offset) { i, _ in
                    Capsule()
                        .fill(i < model.s.itemIndex ? Color.green
                              : (i == model.s.itemIndex ? Color.teal : Color.white.opacity(0.16)))
                        .frame(height: 4)
                }
            }

            Text(model.nextDhikr.map { "التالي: \($0.text)" } ?? "آخر ذكر في المجموعة")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .frame(height: 12)               // 📐 ثابت — كان يدفع الأزرار مع طول النص
                .truncationMode(.tail)

            controlRow
        }
        .padding(.bottom, 2)
    }

    /// صف الأزرار — متاح في الوضعين (العدّ والقراءة) حتى لا يبقى المستخدم بلا أدوات
    private var controlRow: some View {
        HStack(spacing: 6) {

            // − تراجع (لتصحيح ضغطة خاطئة) — الوضع العادي فقط
            if !model.readingMode {
                Button { model.decrement() } label: {
                    Image(systemName: "minus").font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.bordered).tint(.gray)
            }

            // ↺ تصفير — يعمل دائمًا ويُظهر رسالة تأكيد
            Button { model.resetCurrent() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.bordered).tint(.gray)
            .accessibilityLabel("تصفير الذكر الحالي")

            // 👁️ الرؤية من بعيد — الوضع العادي فقط (في وضع القراءة صار في أعلى الشاشة)
            if !model.readingMode {
                Button { model.toggleDistanceMode() } label: {
                    Image(systemName: "eye")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(model.distanceMode ? .teal : .gray)
                .accessibilityLabel(model.distanceMode ? "إيقاف الرؤية من بعيد" : "تشغيل الرؤية من بعيد")
            }

            // 📜 التلقين — يفتح وضع القراءة ويبدأ التمرير (الوضع العادي فقط؛
            //     في وضع القراءة يوجد زر التلقين في شريط الأدوات)
            if !model.readingMode {
                Button {
                    if !model.readingMode { model.toggleReadingMode() }
                    model.togglePromptPause()      // يشغّل التلقين إن كان موقوفًا
                } label: {
                    Image(systemName: "text.line.first.and.arrowtriangle.forward")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered).tint(.gray)
                .accessibilityLabel("بدء التلقين")
            }
        }
        .frame(height: 30)                       // 📐 ثابت: أيقونات مختلفة الأطوال
    }

    // MARK: - وميض إكمال الذكر

    private func flashOverlay(_ name: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(.green)
            Text("أكملت \(name)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 18))
        .allowsHitTesting(false)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - عرض النص الكامل في نافذة مستقلة (الوضع العادي)

struct FullTextView: View {
    let dhikr: Dhikr
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 10) {
                Text(dhikr.text)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.teal)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if let full = dhikr.full {
                    Text(full)
                        .font(.system(size: 13))
                        .lineSpacing(4)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if dhikr.target > 0 {
                    Text("العدد: \(dhikr.target)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("نص الذكر")
        .toolbar { ToolbarItem(placement: .cancellationAction) {
            Button("إغلاق") { dismiss() }
        }}
    }
}

#Preview { CounterView() }
