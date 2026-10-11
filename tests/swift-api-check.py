#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🔍 فاحص تطابق واجهات Swift ومحتوى الأذكار
سبحة — أداة تُشغَّل قبل كل تسليم (بدون Mac)

يفحص:
  ① أن كل نداء `SharedCounter.xxx()` / `SharedKeys.xxx` موجود فعلًا في Shared.swift
     (مع تجاهل التعليقات — درسٌ من خطأ `SharedCounter.increment()` المحذوفة)
  ② أن كل ملف مصدر مذكور في project.yml / project-container.yml موجود فعليًا
  ③ أن نصوص الأذكار الكاملة متطابقة بين Swift و المحاكي (عدد + المحتوى)

الاستخدام:  python3 tests/swift-api-check.py
"""

import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ok_all = True


def strip_comments(src: str) -> str:
    """يحذف تعليقات // و /* */ حتى لا نُبلّغ عن نداءات موجودة في الشرح فقط."""
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    out = []
    for line in src.splitlines():
        # تجاهل ما بعد // مع مراعاة عدم وجود // داخل نص عادي (تقريب كافٍ هنا)
        idx = line.find('//')
        out.append(line[:idx] if idx >= 0 else line)
    return '\n'.join(out)


def check_apis() -> bool:
    shared = strip_comments((ROOT / 'Shared.swift').read_text(encoding='utf-8'))
    funcs = set(re.findall(r'static func (\w+)', shared))
    keys = set(re.findall(r'static let (\w+)\s*=', shared))

    targets = ['Widget/IncrementIntent.swift', 'Widget/TasbihWidget.swift', 'CounterModel.swift',
               'CounterView.swift', 'ReadingView.swift', 'OptionsPanel.swift', 'MenuView.swift',
               'SetBackgrounds.swift', 'TasbihApp.swift', 'SessionManager.swift', 'Shared.swift']
    bad = []
    for f in targets:
        p = ROOT / f
        if not p.exists():
            continue
        src = strip_comments(p.read_text(encoding='utf-8'))
        for m in re.finditer(r'SharedCounter\.(\w+)\s*\(', src):
            if m.group(1) not in funcs:
                bad.append(f'{f}: SharedCounter.{m.group(1)}() غير موجودة')
        for m in re.finditer(r'SharedKeys\.(\w+)', src):
            if m.group(1) not in keys:
                bad.append(f'{f}: SharedKeys.{m.group(1)} غير موجود')

    print('① نداءات الكود المشترك')
    if bad:
        for b in bad:
            print('   ✘ ' + b)
        return False
    print(f'   ✔ {len(targets)} ملفًا · لا نداء لدالة أو مفتاح محذوف')
    return True


def check_sources() -> bool:
    print('② مصادر ملفات المشروع (yml)')
    try:
        import yaml
    except ImportError:
        print('   ⚠ PyYAML غير مثبّت — تخطّي (pip install pyyaml)')
        return True
    ok = True
    for name in ['project.yml', 'project-container.yml']:
        p = ROOT / name
        if not p.exists():
            continue
        d = yaml.safe_load(p.read_text(encoding='utf-8'))
        miss = []
        for _, t in (d.get('targets') or {}).items():
            for s in (t.get('sources') or []):
                path = s if isinstance(s, str) else s.get('path', '')
                if path and not (ROOT / path.rstrip('/')).exists():
                    miss.append(path)
        if miss:
            ok = False
            print(f'   ✘ {name}: مصادر مفقودة {miss}')
        else:
            print(f'   ✔ {name}: كل المصادر موجودة')
    return ok


def check_dhikr_parity() -> bool:
    print('③ تطابق نصوص الأذكار الكاملة (Swift ↔ المحاكي)')
    sim = (ROOT / 'simulator.html').read_text(encoding='utf-8')
    sw = (ROOT / 'Shared.swift').read_text(encoding='utf-8')

    k = sim.find('const FULL = {')
    sim_full = {}
    if k >= 0:
        for m in re.finditer(r'"([^"]+)"\s*:\s*"((?:[^"\\]|\\.)*)"', sim[k:sim.find('\n};', k)]):
            sim_full[m.group(1)] = m.group(2)

    block = sw[sw.find('adhkarSets'):]
    sw_full = {}
    for m in re.finditer(r'Dhikr\((.*?)\)\s*,?\s*(?=Dhikr\(|\])', block, re.S):
        body = ' '.join(m.group(1).split())
        t = re.search(r'text:\s*"((?:[^"\\]|\\.)*)"', body)
        f = re.search(r'full:\s*"((?:[^"\\]|\\.)*)"', body)
        if t and f:
            sw_full[t.group(1)] = f.group(1)

    only_sw = sorted(set(sw_full) - set(sim_full))
    only_sim = sorted(set(sim_full) - set(sw_full))
    diff = sorted(n for n in set(sim_full) & set(sw_full) if sim_full[n] != sw_full[n])

    print(f'   أسماء بنص كامل — Swift: {len(sw_full)} · المحاكي: {len(sim_full)}')
    for n in only_sw:
        print(f'   ✘ في Swift فقط: {n}')
    for n in only_sim:
        print(f'   ✘ في المحاكي فقط: {n}')
    for n in diff:
        print(f'   ✘ النص مختلف في: {n}')
    if only_sw or only_sim or diff:
        return False
    print('   ✔ الأسماء والنصوص متطابقة تمامًا')
    return True


def check_model_members() -> bool:
    """يتأكد أن كل مرجع `model.x` و`session.x` في الواجهات موجود فعلًا في النموذجين.
       هذا يلتقط خطأ الإملاء في اسم خاصية — وهو أكثر خطأ يوقف الترجمة."""
    print('④ مراجع النماذج (model.x / session.x)')

    def members(path):
        src = re.sub(r'/\*.*?\*/', '', path.read_text(encoding='utf-8'), flags=re.S)
        src = '\n'.join(l[:l.find('//')] if '//' in l else l for l in src.splitlines())
        names = set(re.findall(r'(?:var|let)\s+(\w+)', src))
        names |= set(re.findall(r'func\s+(\w+)', src))
        names |= set(re.findall(r'case\s+(\w+)', src))
        return names

    cm = members(ROOT / 'CounterModel.swift')
    sm = members(ROOT / 'SessionManager.swift')
    bad = []
    for f in ['CounterView.swift', 'ReadingView.swift', 'OptionsPanel.swift',
              'MenuView.swift', 'TasbihApp.swift', 'SetBackgrounds.swift']:
        p = ROOT / f
        if not p.exists():
            continue
        src = p.read_text(encoding='utf-8')
        for m in re.finditer(r'\bmodel\.(\w+)', src):
            if m.group(1) not in cm:
                bad.append(f'{f}: model.{m.group(1)}')
        for m in re.finditer(r'\bsession\.(\w+)', src):
            if m.group(1) not in sm:
                bad.append(f'{f}: session.{m.group(1)}')
    if bad:
        for b in sorted(set(bad)):
            print('   ✘ ' + b)
        return False
    print(f'   ✔ لا مراجع مفقودة (CounterModel: {len(cm)} عضوًا · SessionManager: {len(sm)})')
    return True


def check_risky_apis() -> bool:
    """⓺ رموز محرّمة + واجهات سبق أن أوقفت الترجمة.
       (درس: `.gestureButton` غير موجودة في HandGestureShortcut ⇒ ٤ أخطاء في أول بناء على أبل.)"""
    print('⑥ واجهات محرّمة ومكرّرة (سبب فشل الترجمة الأول)')

    forbidden = {
        '.gestureButton': 'غير موجودة في HandGestureShortcut (الوحيدة: .primaryAction)',
        'SharedCounter.increment(': 'دالة محذوفة — الصحيح SharedCounter.tap()',
        'SettingsView(': 'شاشة محذوفة من المشروع',
        'menuAction': 'الاسم الصحيح menuAct',
    }
    files = sorted(list(ROOT.glob('*.swift')) + list((ROOT / 'Widget').glob('*.swift')))
    bad = []
    for f in files:
        for i, line in enumerate(f.read_text(encoding='utf-8').splitlines(), 1):
            code = line.split('//')[0]
            for sym, why in forbidden.items():
                if sym in code:
                    bad.append(f'{f.name}:{i} → {sym} ({why})')
    # كل استدعاء للإيماءة يجب أن يكون .primaryAction حصرًا
    for f in files:
        for m in re.finditer(r'handGestureShortcut\(\s*\.(\w+)', f.read_text(encoding='utf-8')):
            if m.group(1) != 'primaryAction':
                bad.append(f'{f.name}: handGestureShortcut(.{m.group(1)}) — الوحيدة المدعومة: .primaryAction')
    # تصريحات مكرّرة في نفس الهدف = خطأ ترجمة مؤكّد
    seen = {}
    for f in files:
        src = re.sub(r'//.*', '', f.read_text(encoding='utf-8'))
        for m in re.finditer(r'^(?:public |internal |private |final )*(?:struct|enum|class|actor)\s+(\w+)', src, re.M):
            seen.setdefault(m.group(1), []).append(f.name)
    for name, where in seen.items():
        if len(set(where)) > 1:
            bad.append(f'تصريح مكرّر: {name} في {sorted(set(where))}')

    # (درس ٢) وزن الخط في SwiftUI يقبل == فقط — لا >= ولا <=  ⇒ خطأ ترجمة مؤكّد
    for f in files:
        for i, line in enumerate(f.read_text(encoding='utf-8').splitlines(), 1):
            code = line.split('//')[0]
            if re.search(r'[<>]=\s*\.(?:ultraLight|thin|light|regular|medium|semibold|bold|heavy|black)\b', code):
                bad.append(f'{f.name}:{i} — Font.Weight لا يقبل المقارنة (≥/≤)؛ استعمل == أو قائمة contains')

    # (درس ٣) كل ملف يستعمل واجهة UIKit يجب أن يُعلن `import UIKit` بنفسه
    for f in files:
        code = re.sub(r'//.*', '', f.read_text(encoding='utf-8'))
        if re.search(r'\b(?:UIFont|UIColor|UIImage|UIScreen)\b', code) and 'import UIKit' not in code:
            bad.append(f'{f.name} — يستعمل واجهات UIKit بلا «import UIKit» في الملف نفسه')

    if bad:
        for b in bad:
            print('   ✘ ' + b)
        return False
    n_calls = sum(len(re.findall(r'handGestureShortcut\(', f.read_text(encoding='utf-8'))) for f in files)
    print(f'   ✔ لا رموز محرّمة · لا تصريحات مكرّرة · {n_calls} استدعاء إيماءة (كلها .primaryAction)')
    return True


def check_assets_and_sources() -> bool:
    """⑧ الخطوط والأصوات + اكتمال قوائم المصادر في ملفي المشروع.
       (درس: ملف جديد لا يُضاف لـ project.yml = ترجمة تفشل بأن «الرمز غير موجود».)"""
    print('⑧ الخطوط والأصوات + اكتمال المصادر')

    ok_all = True

    # ── الخطوط: الملفات موجودة ومُعلنة في UIAppFonts في الملفين ──
    fonts = ['Amiri-Regular.ttf', 'Amiri-Bold.ttf', 'Almarai-Regular.ttf', 'Almarai-Bold.ttf']
    for f in fonts:
        if not (ROOT / 'Fonts' / f).exists():
            print(f'   ✘ ملف الخط مفقود: Fonts/{f}'); ok_all = False
    for yml in ['project.yml', 'project-container.yml']:
        src = (ROOT / yml).read_text(encoding='utf-8')
        if 'UIAppFonts' not in src:
            print(f'   ✘ {yml}: لا توجد قائمة UIAppFonts'); ok_all = False
        for f in fonts:
            # يجب أن يكون الاسم داخل قسم UIAppFonts (تحقّق بسيط: موجود في الملف بعد كلمة UIAppFonts)
            if src.find('UIAppFonts') >= 0 and f not in src[src.find('UIAppFonts'):src.find('UIAppFonts') + 400]:
                print(f'   ✘ {yml}: الخط {f} غير مُعلن في UIAppFonts'); ok_all = False
        if 'Fonts' not in src:
            print(f'   ✘ {yml}: مجلد Fonts غير مضاف إلى مصادر الهدف'); ok_all = False
    if ok_all:
        print(f'   ✔ {len(fonts)} خطوط مرفقة ومُعلنة في الملفين')

    # ── الأصوات: الملفات موجودة ومضافة للمصادر ومرتبطة في Sounds.swift ──
    sounds = ['click_soft.wav', 'chime_soft.wav']
    for f in sounds:
        if not (ROOT / 'Sounds' / f).exists():
            print(f'   ✘ ملف صوت مفقود: Sounds/{f}'); ok_all = False
    code = (ROOT / 'Sounds.swift').read_text(encoding='utf-8')
    for stem in ['click_soft', 'chime_soft']:
        if stem not in code:
            print(f'   ✘ Sounds.swift لا يشير إلى {stem}'); ok_all = False
    for yml in ['project.yml', 'project-container.yml']:
        if '- path: Sounds' not in (ROOT / yml).read_text(encoding='utf-8'):
            print(f'   ✘ {yml}: مجلد Sounds غير مضاف للمصادر'); ok_all = False
    if ok_all:
        print(f'   ✔ {len(sounds)} ملفات صوت مرفقة ومربوطة')

    # ── اكتمال المصادر: كل ملف Swift في الجذر يجب أن يكون في ملفي المشروع ──
    swift_files = sorted(f.name for f in ROOT.glob('*.swift'))
    for yml in ['project.yml', 'project-container.yml']:
        src = (ROOT / yml).read_text(encoding='utf-8')
        missing = [f for f in swift_files if f not in src]
        if missing:
            print(f'   ✘ {yml}: ملفات غير مُضافة: {missing}'); ok_all = False
    if ok_all:
        print(f'   ✔ كل ملفات Swift ({len(swift_files)}) مُضافة في ملفي المشروع')

    # ── عدد المجموعات متطابق بين Swift والمحاكي ──
    sw = (ROOT / 'Shared.swift').read_text(encoding='utf-8')
    sw_sets = len(re.findall(r'^    DhikrSet\(', sw, re.M))
    sim = (ROOT / 'simulator.html').read_text(encoding='utf-8')
    sim_block = sim[sim.find('const SETS = ['):sim.find('\n];', sim.find('const SETS = ['))]
    sim_sets = len(re.findall(r'\{ id:"', sim_block))
    if sw_sets != sim_sets or sw_sets < 8:
        print(f'   ✘ عدد المجموعات مختلف: Swift {sw_sets} · المحاكي {sim_sets}'); ok_all = False
    else:
        print(f'   ✔ عدد المجموعات متطابق: {sw_sets} في الاثنين')

    return ok_all


def check_app_group() -> bool:
    print('⑨ صلاحية مجموعة التطبيق (App Group)')
    try:
        import yaml
    except ImportError:
        print('   ⚠ PyYAML غير مثبّت — تخطّي')
        return True
    shared = (ROOT / 'Shared.swift').read_text(encoding='utf-8')
    m = re.search(r'appGroupID\s*=\s*"([^"]+)"', shared)
    want = m.group(1) if m else None
    print(f'   المعرّف في Shared.swift: {want}')
    ok = True
    for name in ['project.yml', 'project-container.yml']:
        p = ROOT / name
        if not p.exists():
            continue
        d = yaml.safe_load(p.read_text(encoding='utf-8'))
        for tname, t in (d.get('targets') or {}).items():
            srcs = [x if isinstance(x, str) else x.get('path', '') for x in (t.get('sources') or [])]
            if not any('Shared.swift' in str(x) for x in srcs):
                continue                      # لا يستخدم الكود المشترك ⇒ لا يحتاج الصلاحية
            groups = (((t.get('entitlements') or {}).get('properties') or {})
                      .get('com.apple.security.application-groups')) or []
            if want in groups:
                print(f'   ✔ {name} · {tname}')
            else:
                ok = False
                print(f'   ✘ {name} · {tname}: صلاحية مجموعة التطبيق مفقودة أو مختلفة')
    if ok:
        print('   ✔ كل هدف يقرأ الكود المشترك يملك الصلاحية نفسها')
    return ok


def check_scheme_runnable() -> bool:
    """⑩ هدف التشغيل في كل مخطط.

    درس من فحص الترجمة (exit 70): XcodeGen **يرتّب أهداف المخطط أبجديًا** ويربط
    هدف التشغيل بأول هدف قابل للتشغيل — لا باسم المخطط. ففي ملف الحاوية:
    «Tasbih» (ساعة) تأتي قبل «TasbihContainer» (آيفون) ⇒ يصبح المخطط «ساعة»
    ويقول xcodebuild: «لا توجد وجهة iOS». الحلّ: `run.executable` في المخطط."""
    print('⑩ هدف التشغيل في المخططات (سبب فشل الترجمة الثاني)')
    try:
        import yaml
    except ImportError:
        print('   ⚠ PyYAML غير مثبّت — تخطّي')
        return True

    expected = {
        'project.yml':           {'Tasbih': 'Tasbih'},
        'project-container.yml': {'TasbihContainer': 'TasbihContainer', 'Tasbih': 'Tasbih'},
    }
    ok = True
    for name, want in expected.items():
        p = ROOT / name
        if not p.exists():
            continue
        d = yaml.safe_load(p.read_text(encoding='utf-8'))
        targets = d.get('targets') or {}
        for scheme, exe in want.items():
            sch = (d.get('schemes') or {}).get(scheme)
            if sch is None:
                ok = False
                print(f'   ✘ {name}: المخطط «{scheme}» مفقود')
                continue
            for t in (sch.get('build', {}).get('targets') or {}):
                if t not in targets:
                    ok = False
                    print(f'   ✘ {name} · مخطط {scheme}: الهدف «{t}» غير موجود في الملف')
            got = (sch.get('run') or {}).get('executable')
            if got == exe:
                print(f'   ✔ {name} · مخطط {scheme} ⇒ هدف التشغيل: {got}')
            else:
                ok = False
                print(f'   ✘ {name} · مخطط {scheme}: run.executable = {got!r} (المطلوب {exe!r})'
                      ' — بدونه يختار XcodeGen هدفًا أبجديًا خاطئًا ⇒ «لا توجد وجهة»')
    return ok


def check_debug_shots() -> bool:
    """⑪ مدخل لقطات المتجر لا يتسرّب إلى نسخة المتجر.

    `DebugShots.swift` محصور بالكامل بين #if DEBUG و #endif (يُحذف من نسخة
    المتجر). وأي استعمال لِـ SabhaShot في ملف آخر يجب أن يكون هو الآخر داخل
    #if DEBUG — وإلا فشلت ترجمة نسخة Release بأن «الرمز غير موجود».
    (لقطة الودجت في المتجر لا تكفي: هذا فحص يمنع مفاجأة وقت النشر.)"""
    print('⑪ مدخل لقطات المتجر (لا يتسرّب إلى نسخة المتجر)')
    shots = ROOT / 'DebugShots.swift'
    if not shots.exists():
        print('   ⚠ DebugShots.swift غير موجود — تخطّي')
        return True
    src = shots.read_text(encoding='utf-8')
    ok = True
    # نعدّ أسطر التوجيه نفسها (لا الإشارات داخل التعليقات)
    dirs_if = sum(1 for ln in src.splitlines() if ln.strip() == '#if DEBUG')
    dirs_end = sum(1 for ln in src.splitlines() if ln.strip() == '#endif')
    if dirs_if < 1 or dirs_if != dirs_end:
        ok = False
        print(f'   ✘ DebugShots.swift: توجيهات غير متوازنة (#if DEBUG: {dirs_if} · #endif: {dirs_end})')

    files = sorted(list(ROOT.glob('*.swift')) + list((ROOT / 'Widget').glob('*.swift')))
    offenders = []
    for f in files:
        if f.name == 'DebugShots.swift':
            continue
        depth = 0
        for i, line in enumerate(f.read_text(encoding='utf-8').splitlines(), 1):
            stripped = line.strip()
            if stripped == '#if DEBUG':
                depth += 1
            elif stripped == '#endif' and depth > 0:
                depth -= 1
            if 'SabhaShot' in line.split('//')[0] and depth == 0:
                offenders.append(f'{f.name}:{i}')
    if offenders:
        ok = False
        for o in offenders:
            print(f'   ✘ {o}: استعمال SabhaShot خارج #if DEBUG')
    if ok:
        uses = sum(len(re.findall(r'SabhaShot', (ROOT / f).read_text(encoding='utf-8')))
                   for f in ['TasbihApp.swift', 'CounterView.swift', 'MenuView.swift']
                   if (ROOT / f).exists())
        print(f'   ✔ SabhaShot محصور في #if DEBUG ({uses} استعمالًا في التطبيق)')
    return ok


if __name__ == '__main__':
    ok_all = (check_apis() and check_sources() and check_dhikr_parity()
              and check_model_members() and check_risky_apis()
              and check_assets_and_sources() and check_app_group()
              and check_scheme_runnable() and check_debug_shots())
    print()
    print('📊 النتيجة:', '✔ كل الفحوصات سليمة' if ok_all else '❌ توجد مشاكل أعلاه')
    sys.exit(0 if ok_all else 1)
