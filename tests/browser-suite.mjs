/**
 * ════════════════════════════════════════════════════════════════════════
 *  سبحة — حزمة الاختبار بمتصفح حقيقي (Puppeteer)
 * ════════════════════════════════════════════════════════════════════════
 *  لماذا متصفح حقيقي؟ jsdom لا يملك محرّك تخطيط: كل الارتفاعات صفر، فلا
 *  يكشف انزياح الأزرار ولا خروج العناصر عن شاشة الساعة. هذا الاختبار هو
 *  الذي اكتشف عيب `position:relative` الذي كان يدفع الأزرار خارج الشاشة.
 *
 *  التشغيل:
 *     cd tests && npm install puppeteer
 *     node browser-suite.mjs
 *
 *  يفحص:
 *   ① الحدود  : لا عنصر يخرج عن شاشة الساعة (٩ حالات عرض)
 *   ② الثبات  : موضع الأزرار والحلقة والعدّاد عبر ٣٧ ذكرًا — انزياح ٠ بكسل
 *   ③ الترتيب : الشريط أعلى اسم الذكر · العدّاد أعلى يمين الشاشة
 *   ④ القائمة : تُخفي الشريط والعدّاد عند فتحها
 *   ⑤ التلقين : يتحرك فعلًا · الأثير (AOD) · المجموعات · الودجت
 * ════════════════════════════════════════════════════════════════════════
 */
import puppeteer from './node_modules/puppeteer/lib/esm/puppeteer/puppeteer.js';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SIM = 'file://' + path.join(HERE, '..', 'simulator.html');
const SHOTS = path.join(HERE, '..', 'screenshots');

let pass = 0, fail = 0;
const ok = (cond, label, detail = '') => {
  (cond ? pass++ : fail++);
  console.log(`  ${cond ? '✔' : '✘'} ${label}${detail ? ' → ' + detail : ''}`);
};
const head = t => console.log(`\n${t}`);

const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-dev-shm-usage'] });
const page = await browser.newPage();
await page.setViewport({ width: 420, height: 920, deviceScaleFactor: 2 });
const errors = [];
page.on('pageerror', e => errors.push(e.message));
await page.goto(SIM, { waitUntil: 'load' });
await new Promise(r => setTimeout(r, 500));

/* ═══════════ ① و ② الحدود وثبات التخطيط ═══════════ */
head('① الحدود: هل يخرج أي عنصر عن شاشة الساعة؟');

const press = src => page.evaluate(async s => {
  await new Function('return (async()=>{' + s + '})()')();
  await new Promise(r => requestAnimationFrame(r));
  await new Promise(r => setTimeout(r, 60));
}, src);

const bounds = async (label) => {
  const r = await page.evaluate(() => {
    const sc = document.getElementById('screen').getBoundingClientRect();
    const bad = [];
    const inScroller = e => {
      let p = e.parentElement;
      while (p && p.id !== 'screen') {
        const st = getComputedStyle(p);
        if ((st.overflowY === 'auto' || st.overflowY === 'scroll') && p.scrollHeight > p.clientHeight + 1) return true;
        p = p.parentElement;
      }
      return false;
    };
    document.querySelectorAll('#screen *').forEach(e => {
      const st = getComputedStyle(e);
      if (st.display === 'none' || st.visibility === 'hidden' || parseFloat(st.opacity) === 0) return;
      if (inScroller(e)) return;
      if (e.classList.contains('bgimg') || e.classList.contains('bgdim') || e.classList.contains('glow')) return;
      const r = e.getBoundingClientRect();
      if (r.width === 0 && r.height === 0) return;
      const over = Math.max(0, sc.top - r.top, r.bottom - sc.bottom, sc.left - r.left, r.right - sc.right);
      if (over > 1) bad.push((e.id ? '#' + e.id : '.' + String(e.className).split(' ')[0]) + ' ' + over.toFixed(0) + 'px');
    });
    return bad;
  });
  ok(r.length === 0, label, r.length ? r.slice(0, 4).join(' · ') : '');
};

for (const [label, setup] of [
  ['وضع العدّ — ذكر قصير', "S.si=0;S.ii=3;S.c=12;S.read=false;render();applyLayout();"],
  ['وضع العدّ — آية الكرسي', "S.si=0;S.ii=2;S.c=0;S.read=false;render();applyLayout();"],
  ['وضع العدّ — بلا حد (مفتوح)', "S.si=5;S.ii=0;S.c=340;S.read=false;render();applyLayout();"],
  ['وضع القراءة + تلقين', "S.si=0;S.ii=2;S.read=true;S.prompt=true;render();applyLayout();"],
  ['وضع القراءة — عن بُعد', "S.dist=true;render();applyLayout();"],
  ['صفحة المجموعات', "S.dist=false;S.read=false;render();applyLayout();openMenu('sets');"],
  ['صفحة الودجت', "openMenu('widget');"],
  ['القائمة المنسدلة', "openMenu('main');"],
  ['وضع الجلسة الممتدة (AOD)', "closeMenu();S.aod=true;render();applyLayout();"],
]) { await press(setup); await bounds(label); }
await press("closeMenu();S.aod=false;S.prompt=false;render();applyLayout();");

/* ═══════════ ثبات المواضع عبر كل الأذكار ═══════════ */
head('② الثبات: مواضع العناصر عبر كل الأذكار (٣٧ ذكرًا × وضعان)');

const drift = await page.evaluate(async () => {
  const box = s => { const e = document.querySelector(s); const r = e.getBoundingClientRect();
    return { y: +r.y.toFixed(1), b: +r.bottom.toFixed(1), x: +r.x.toFixed(1), r: +r.right.toFixed(1) }; };
  const raf = () => new Promise(r => requestAnimationFrame(r));
  const rows = [];
  for (let si = 0; si < SETS.length; si++) for (let ii = 0; ii < SETS[si].items.length; ii++) {
    S.si = si; S.ii = ii; S.c = 0;
    S.read = false; render(); applyLayout(); await raf();
    const a = { btnTop: box('.btnrow').y, ring: box('#ring').y, menu: box('#menuBtn').y };
    S.read = true; render(); applyLayout(); await raf();
    const b = { badgeX: box('#badge').x, badgeY: box('#badge').y, barY: box('.promptbar').y,
                titleY: box('.rdTitle').y, screen: box('#screen') };
    rows.push({ ...a, ...b, name: SETS[si].items[ii].t });
  }
  return rows;
});
const uniq = k => [...new Set(drift.map(r => r[k]))];
const stable = (k, label) => ok(uniq(k).length === 1, label, `قيمة واحدة: ${uniq(k)[0]}`);
stable('btnTop', 'صف الأزرار ثابت في كل الأذكار');
stable('ring', 'الحلقة ثابتة في كل الأذكار');
stable('menu', 'زر ☰ ثابت');
stable('badgeX', 'العدّاد: موضعه الأفقي ثابت');
stable('badgeY', 'العدّاد: موضعه الرأسي ثابت');
stable('barY', 'شريط التلقين ثابت');
const s0 = drift[0];
ok(s0.badgeX > s0.screen.x + (s0.screen.r - s0.screen.x) / 2, 'العدّاد في النصف الأيمن من الشاشة',
   `x=${s0.badgeX} مقابل المنتصف ${((s0.screen.x + s0.screen.r) / 2).toFixed(1)}`);
ok(s0.badgeY < s0.screen.y + (s0.screen.b - s0.screen.y) / 2, 'العدّاد في النصف الأعلى', `y=${s0.badgeY}`);
ok(s0.barY < s0.titleY, 'شريط التلقين فوق اسم الذكر', `الشريط ${s0.barY} < الاسم ${s0.titleY}`);

/* ═══════════ ③ القائمة تُخفي الطبقات الطافية ═══════════ */
head('③ القائمة المنسدلة: تُخفي الشريط والعدّاد عند فتحها');
const menuVis = await page.evaluate(async () => {
  const raf = () => new Promise(r => requestAnimationFrame(r));
  const vis = id => getComputedStyle(document.getElementById(id)).display !== 'none';
  S.si = 0; S.ii = 2; S.read = true; render(); applyLayout(); await raf();
  const before = vis('promptBar') && vis('badge');
  openMenu('main'); await raf();
  const open = !vis('promptBar') && !vis('badge');
  closeMenu(); await raf();
  const after = vis('promptBar') && vis('badge');
  return { before, open, after };
});
ok(menuVis.before, 'قبل الفتح: الشريط والعدّاد ظاهران');
ok(menuVis.open, 'بعد الفتح: اختفيا (لا طفو فوق القائمة)');
ok(menuVis.after, 'بعد الإغلاق: عادا');

/* ═══════════ ④ التلقين يتحرك فعلًا ═══════════ */
head('④ التلقين: تمرير فعلي بوتيرة القراءة');
const prompt = await page.evaluate(async () => {
  const raf = () => new Promise(r => requestAnimationFrame(r));
  outer: for (let si = 0; si < SETS.length; si++) for (let ii = 0; ii < SETS[si].items.length; ii++)
    if (SETS[si].items[ii].t.includes('الْكُرْسِيّ')) { S.si = si; S.ii = ii; break outer; }
  S.read = true; S.fs = 1; S.prompt = false; S.paused = false; render(); applyLayout(); await raf();
  const maxY = promptTotal(), speed = promptSpeed();
  startPrompt();
  await new Promise(r => setTimeout(r, 3000));
  const y = el.rdScroll.scrollTop;
  const badgeBottom = document.getElementById('badge').getBoundingClientRect().bottom;
  const barBottom = document.querySelector('.promptbar').getBoundingClientRect().bottom;
  const screenBottom = document.getElementById('screen').getBoundingClientRect().bottom;
  return { maxY, speed, y, badgeInside: badgeBottom <= screenBottom, barInside: barBottom <= screenBottom };
});
ok(prompt.y > 0.05, 'النص يتحرك فعلًا أثناء التلقين', `scrollTop=${prompt.y.toFixed(1)}px من ${prompt.maxY.toFixed(1)}px بسرعة ${prompt.speed.toFixed(2)}px/ث`);
ok(prompt.badgeInside && prompt.barInside, 'العدّاد والشريط ثابتان داخل الشاشة أثناء التمرير');

/* ═══════════ ⑤ المحتوى: النصوص الكاملة ═══════════ */
head('⑤ المحتوى: نصوص وضع القراءة');
const content = await page.evaluate(async () => {
  const raf = () => new Promise(r => requestAnimationFrame(r));
  const out = { entries: Object.keys(FULL).length, ayat: FULL['آيَةُ الْكُرْسِيّ'].length,
    tahlilNote: FULL['لَا إِلَهَ إِلَّا اللَّه وَحْدَهُ…'].includes('تمام المائة'),
    dupRemoved: !('بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا' in FULL) };
  outer: for (let si = 0; si < SETS.length; si++) for (let ii = 0; ii < SETS[si].items.length; ii++)
    if (SETS[si].items[ii].t === 'الْمُعَوِّذَات مَعَ النَّفْث') { S.si = si; S.ii = ii; break outer; }
  S.read = true; render(); applyLayout(); await raf();
  out.multiLine = document.getElementById('rdText').innerHTML.includes('<br>');
  return out;
});
ok(content.entries === 17, 'عدد النصوص الكاملة ١٧ (مطابق لـ Swift)', String(content.entries));
ok(content.ayat === 404, 'آية الكرسي كاملة (٤٠٤ حروف)', String(content.ayat));
ok(content.tahlilNote, 'تفسير الذكر المتمّم للمائة موجود');
ok(content.dupRemoved, 'المدخل المكرّر محذوف (لا تكرار)');
ok(content.multiLine, 'المعوذات تُعرض في أسطر (السور مفصولة)');

/* ═══════════ لقطات ═══════════ */
head('⑥ اللقطات');
const shots = [
  ['01-العد-ذكر-قصير.png', "S.si=0;S.ii=3;S.c=12;S.read=false;render();applyLayout();"],
  ['02-العد-آية-الكرسي.png', "S.si=0;S.ii=2;S.c=0;S.read=false;render();applyLayout();"],
  ['03-القراءة-آية-الكرسي.png', "S.si=0;S.ii=2;S.c=7;S.read=true;render();applyLayout();"],
  ['04-القراءة-عن-بعد.png', "S.dist=true;render();applyLayout();"],
  ['05-القائمة-المنسدلة.png', "S.dist=false;S.read=false;render();applyLayout();openMenu('main');"],
  ['06-المجموعات.png', "closeMenu();render();applyLayout();openMenu('sets');"],
  // ── تحديث v2 ──
  ['10-الإحصاءات.png', "closeMenu();S.si=0;S.ii=3;S.read=false;S.hist={'2026-10-11':42};S.histTotal=42;render();applyLayout();openMenu('stats');"],
  ['11-شاشة-التعريف.png', "closeMenu();openMenu('howto');"],
  ['12-الصوت-والاهتزاز.png', "closeMenu();openMenu('main');document.querySelector('#menu').scrollTop=200;"],
];
for (const [name, setup] of shots) {
  await press(setup);
  const el = await page.$('#screen');
  await el.screenshot({ path: path.join(SHOTS, name) });
}
console.log(`  ✔ حُفظت ${shots.length} لقطة في screenshots/`);

ok(errors.length === 0, 'لا أخطاء JavaScript', errors.slice(0, 2).join(' | '));

console.log(`\n${'─'.repeat(58)}`);
console.log(`  النتيجة: ${pass} ✔ · ${fail} ✘`);
await browser.close();
process.exit(fail ? 1 : 0);
