/**
 * ════════════════════════════════════════════════════════════════════════
 *  سبحة — حزمة الاختبار السريع (jsdom)
 * ════════════════════════════════════════════════════════════════════════
 *  تفحص التفاعل والمنطق (لا تخطيط — للقياسات البصرية استخدم browser-suite).
 *  وهي التي كشفت انكسار المحاكي الكامل بسبب زر محذوف كان مربوطًا في الكود.
 *
 *  ملاحظة تقنية: متغيّرات المحاكي مُعلنة بـ const داخل سكربت الصفحة، فهي
 *  روابط معجمية لا خصائص على window — لذلك كل الفحوصات تُنفَّذ بـ window.eval
 *  داخل نطاق الصفحة نفسه.
 *
 *  التشغيل:
 *     cd tests && npm install jsdom
 *     node jsdom-suite.mjs
 * ════════════════════════════════════════════════════════════════════════
 */
import { JSDOM, VirtualConsole } from './node_modules/jsdom/lib/api.js';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SIM = path.join(HERE, '..', 'simulator.html');

let pass = 0, fail = 0;
const ok = (c, label, detail = '') => { c ? pass++ : fail++; console.log(`  ${c ? '✔' : '✘'} ${label}${detail ? ' → ' + detail : ''}`); };
const head = t => console.log(`\n${t}`);

const consoleErrors = [];
const vc = new VirtualConsole();
vc.on('jsdomError', e => consoleErrors.push(e.detail?.message || e.message));

const dom = new JSDOM(fs.readFileSync(SIM, 'utf8'), {
  runScripts: 'dangerously', pretendToBeVisual: true, virtualConsole: vc,
});
await new Promise(r => setTimeout(r, 500));
const { window } = dom, doc = window.document;

/** ينفّذ كودًا داخل نطاق الصفحة (حيث S و el و SETS و FULL مرئية) */
const ev = code => window.eval(code);
const raf = () => new Promise(r => setTimeout(r, 40));

head('① التحميل والربط');
ok(consoleErrors.length === 0, 'لا أخطاء عند التحميل', consoleErrors.slice(0, 2).join(' | '));
ok(!doc.getElementById('errBanner')?.classList.contains('on'), 'شريط الأخطاء المرئي غير ظاهر');
ok(ev('SETS.length') === 8, 'المجموعات الثماني موجودة (بعد إضافة الاستغفار والصلاة على النبي)');
ok(ev("SETS.some(s=>s.id==='istighfar') && SETS.some(s=>s.id==='salawat')"), 'المجموعتان الجديدتان: الاستغفار · الصلاة على النبي ﷺ');
ok(ev('typeof bind === "function"'), 'دالة الربط الآمنة موجودة (كل المعالجات مربوطة)');

head('② العدّ والتصفير');
const c0 = ev('S.c'); ev("tap('test')");
ok(ev('S.c') === c0 + 1, 'النقر يزيد العدّ', `من ${c0} إلى ${ev('S.c')}`);
ev('resetCurrent()'); await raf();
ok(ev('S.c') === 0, 'التصفير يصفّر العدّ');
ok(doc.getElementById('toast').classList.contains('on'), 'تظهر رسالة تأكيد فورية (لا زر صامت)');

head('③ المجموعات والانتقال');
ev("openMenu('sets')");
ok(doc.getElementById('menu').classList.contains('on'), 'صفحة المجموعات تُفتح');
ev('selectSet(1, true)'); await raf();
ok(!doc.getElementById('menu').classList.contains('on'), 'اختيار مجموعة يغلق القائمة');
ok(doc.getElementById('setName').textContent.includes('الصباح'), 'اسم المجموعة تحدّث', doc.getElementById('setName').textContent.trim());
ok(doc.getElementById('dhikr').textContent.trim().length > 0, 'اسم الذكر تحدّث (لا اسم قديم)');

head('④ القائمة المنسدلة: كل الإجراءات في الصفحات الثلاث');
const collect = () => ev('(function(){var a=[];document.querySelectorAll("#menu [data-act]").forEach(function(e){if(a.indexOf(e.dataset.act)<0)a.push(e.dataset.act)});return a})()');
const allCodes = new Set();
for (const pg of ['main', 'sets', 'widget']) { ev(`openMenu(${JSON.stringify(pg)})`); collect().forEach(c => allCodes.add(c)); }
ev("closeMenu()"); await raf();
let bad = 0;
for (const code of allCodes) {
  try { ev(`menuAct(${JSON.stringify(code)})`); } catch (e) { bad++; console.log('     ✘', code, e.message); }
}
ok(allCodes.size > 15 && bad === 0, `${allCodes.size} إجراء في القائمة يعمل بلا أخطاء`, `منها ${[...allCodes].filter(c => c.startsWith('toggle:')).length} مفتاحًا`);
ev("closeMenu(); S.read=false; S.dist=false; S.aod=false; S.bg=true; S.badgeRight=true; render(); applyLayout()");  // نُعيد الحالة بعد جولة المفاتيح

head('⑤ العدّاد في الزاوية العلوية');
ev("S.read=true; S.badgeRight=true; render(); applyLayout()"); await raf();
ok(ev('$("badge").classList.contains("on")'), 'العدّاد يظهر في وضع القراءة');
ok(ev('!$("badge").classList.contains("left")'), 'افتراضيًا في الزاوية اليمنى');
ev('S.badgeRight=false; applyLayout()'); await raf();
ok(ev('$("badge").classList.contains("left")'), 'الخيار ينقله إلى الزاوية اليسرى');
ev('S.badgeRight=true; applyLayout()');

head('⑥ شريط التلقين في الأعلى + القائمة');
ok(ev('$("promptBar").classList.contains("on")'), 'الشريط ظاهر في وضع القراءة');
ok(ev('document.querySelector(".promptbar").previousElementSibling === null'), 'الشريط أول عنصر في طبقة القراءة (فوق اسم الذكر)');
ev("openMenu('main')"); await raf();
ok(ev('!$("promptBar").classList.contains("on") && !$("badge").classList.contains("on")'), 'فتح القائمة يُخفي الشريط والعدّاد');
ev('closeMenu()'); await raf();
ok(ev('$("promptBar").classList.contains("on")'), 'إغلاق القائمة يعيدهما');

head('⑦ الخلفيات');
const rules = ev('(document.documentElement.innerHTML.match(/\\.screen\\.bg-([a-z_]+)\\s*\\.bgimg/g)||[]).length');
ok(rules === 7, '٦ خلفيات + قاعدة التشغيل مضمّنة في CSS', String(rules));
ev("S.read=false; closeMenu()"); await raf();
ok(/bg-on/.test(doc.getElementById('screen').className), 'الخلفية مفعّلة افتراضيًا');
let swaps = 0;
for (let i = 0; i < 6; i++) { ev(`selectSet(${i}, false)`); if (/bg-/.test(doc.getElementById('screen').className)) swaps++; }
ok(swaps === 6, 'كل مجموعة لها خلفية تعمل', `${swaps}/6`);
const embedded = ev('(document.documentElement.innerHTML.match(/data:image\\/jpeg;base64,/g)||[]).length');
ok(embedded === 6, 'الصور مضمّنة داخل الملف (يعمل بلا إنترنت)', String(embedded));

head('⑧ العدّ بلا نظر: نقرة · حركة · تاج');
ev("openMenu('main')"); await raf();
ok(ev("document.querySelector('#menu').textContent.includes('العدّ بلا نظر')"), 'قسم «العدّ بلا نظر» موجود');
ok(ev("!!document.querySelector('#menu [data-act=\"seg:cMode:0\"]')"), 'محدّد طريقة العدّ (نقرة/حركة/تاج)');

// وضع الحركة
ev("menuAct('seg:cMode:1')"); await raf();
ok(ev('S.cMode') === 1, 'التبديل إلى «حركة» يعمل');
ok(ev("getComputedStyle(document.getElementById('btnMotion')).display !== 'none'"), 'زر محاكاة الحركة ظاهر');
ok(ev("!!document.querySelector('#menu [data-act=\"seg:mSens:1\"]')"), 'محدّد الحساسية ظاهر مع وضع الحركة');
ev("closeMenu()"); await raf();
const cBefore = ev('S.c');
ev("document.getElementById('btnMotion').click()"); await raf();
ok(ev('S.c') === cBefore + 1, 'نكزة واحدة = ذكر واحد');
ok(ev('S.motionLevel') > 0, 'مؤشر الحركة يعمل');
ev('toggleAOD()'); await raf();
const cAod = ev('S.c');
ev("document.getElementById('btnMotion').click()"); await raf();
ok(ev('S.c') === cAod + 1, 'العدّ يعمل والشاشة خافتة (وضع السكون) ✓');
ok(ev("(document.getElementById('aodMode')||{}).textContent.includes('الحركة')"), 'شاشة السكون تشرح الوضع');
ev('toggleAOD()'); await raf();

// وضع التاج
ev("openMenu('main'); menuAct('seg:cMode:2')"); await raf();
ok(ev('S.cMode') === 2, 'التبديل إلى «تاج» يعمل');
ok(ev("getComputedStyle(document.getElementById('btnCrown')).display !== 'none'"), 'زر التاج ظاهر');
ev("closeMenu()"); await raf();
const cCrown = ev('S.c');
ev("document.getElementById('btnCrown').click()"); await raf();
ok(ev('S.c') === cCrown + 1, 'نقرة تاج = ذكر واحد');

// تحذير النقرة المزدوجة
ev("openMenu('main'); menuAct('seg:cMode:0')"); await raf();
ok(ev("document.querySelector('#menu').textContent.includes('تحتاج شاشة مضيئة')"), 'تحذير صريح للنقرة المزدوجة');
ev('closeMenu()'); await raf();

head('⑩ التحديث v2 (الأصوات · الإحصاءات · التعريف · السلوك)');

// 🔊 الصوت + شدة الاهتزاز
// ملاحظة: فحص سابق ينقر كل الأزرار، فلا نفترض الحالة الابتدائية — نقيس التغيّر
ev("openMenu('main')"); await raf();
const soundBefore = ev('S.sound');
ev("menuAct('toggle:sound')"); await raf();
ok(ev('S.sound') === !soundBefore, 'مفتاح الصوت يعمل (نقرة + نغمة إتمام)');
ev("menuAct('toggle:sound')"); await raf();
ok(ev('S.sound') === soundBefore, 'ويُطفأ أيضًا (لا يعلق)');
ev("menuAct('seg:hLevel:2')"); await raf();
ok(ev('S.hLevel') === 2, 'شدة الاهتزاز: التبديل إلى «قوي» يعمل');
ev("menuAct('seg:hLevel:0')"); await raf();
ok(ev('S.hLevel') === 0, 'وشدة «ناعم» أيضًا');
ev("menuAct('seg:hLevel:1')"); await raf();

// 📊 صفحة الإحصاءات
ev("tap('gesture'); tap('gesture')"); await raf();
const histBefore = ev('S.histTotal');
ev("openMenu('stats')"); await raf();
ok(ev('S.histTotal') >= 2, 'سجلّ الإحصاءات يُحسب مع كل ذكر (الإجمالي: ' + histBefore + '→' + ev('S.histTotal') + ')');
ok(ev("document.querySelectorAll('#menu .hbar').length") === 7, 'أعمدة آخر ٧ أيام (٧ أعمدة)');
ok(ev("document.querySelector('#menu').textContent.includes('ذكرًا اليوم')"), 'العدد الكبير «ذكرًا اليوم» ظاهر');
ok(ev("document.querySelector('#menu').textContent.includes('سلسلة')"), 'سلسلة الأيام المتتالية ظاهرة');

// ❓ صفحة التعريف (شاشة الترحيب)
ev("openMenu('howto')"); await raf();
ok(ev("document.querySelectorAll('#menu .hcard').length") === 3, 'شاشة التعريف: ٣ بطاقات (نقرة · حركة · قراءة)');
ok(ev("!!document.querySelector('#menu [data-act=\"close\"]')"), 'زر «ابدأ التسبيح» يغلق التعريف');

// 🆕 المجموعتان الجديدتان في قائمة المجموعات
ev("openMenu('sets')"); await raf();
ok(ev("!!document.querySelector('#menu [data-act=\"set:5\"]')"), 'الاستغفار في قائمة المجموعات');
ok(ev("!!document.querySelector('#menu [data-act=\"set:6\"]')"), 'الصلاة على النبي ﷺ في قائمة المجموعات');
ev("menuAct('set:5')"); await raf();
ok(ev('set().id') === 'istighfar', 'اختيار مجموعة الاستغفار يعمل');
ev("menuAct('set:6')"); await raf();
ok(ev('set().id') === 'salawat', 'واختيار الصلاة على النبي يعمل');
ev("menuAct('set:0')"); await raf();

// 🎨 اللغة البصرية الجديدة
ok(ev("getComputedStyle(document.documentElement).getPropertyValue('--emerald').trim()") !== '', 'لوحة الألوان الجديدة (زمردي) مُعرَّفة');
ok(ev("!!document.getElementById('ringGrad')"), 'تدرّج الحلقة الزمردي موجود في SVG');

head('⑨ النصوص الكاملة');
ok(ev("FULL['آيَةُ الْكُرْسِيّ'].length") === 404, 'آية الكرسي كاملة (٤٠٤ حروف)');
ok(ev('Object.keys(FULL).length') === 17, '١٧ نصًا كاملًا (مطابق لـ Swift)');

console.log(`\n${'─'.repeat(58)}`);
console.log(`  النتيجة: ${pass} ✔ · ${fail} ✘`);
process.exit(fail ? 1 : 0);
