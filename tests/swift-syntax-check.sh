#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════
#  فحص صياغة Swift — يكشف الخطأ «قبل» انتظار سيرفر macOS
# ════════════════════════════════════════════════════════════════════════
#  لماذا هذا الملف موجود؟
#     في نسخة v2 سقطت **فاصلة واحدة** بين مجموعتين في Shared.swift، فمرّت
#     كل الفحوصات الأخرى… ثم فشلت ترجمة الودجت على سيرفر أبل.
#     هذا السكربت يقرأ كل ملفات Swift بالمترجم الرسمي ويكشف مثل هذا الخطأ
#     في ثوانٍ، على أي جهاز (وليس على Mac فقط).
#
#  الاستخدام:   bash tests/swift-syntax-check.sh
#
#  • الملفات كلها: فحص «صياغة» فقط (بلا الحاجة لواجهات أبل).
#  • Shared.swift: فحص كامل (تعريفات + أنواع) لأنه لا يستعمل إلا Foundation.
#  • إن لم يوجد مترجم swiftc: يُتخطّى بأمان وما يفشل شيء.
# ════════════════════════════════════════════════════════════════════════
set -u
cd "$(dirname "$0")/.."          # جذر المشروع

# ── إيجاد المترجم: نظامي، أو نسخة محمّلة يدويًا للبيئة التطويرية ──
SWIFTC="$(command -v swiftc || true)"
if [ -z "$SWIFTC" ]; then
  for c in "${SWIFT_TOOLCHAIN:-}" "$HOME/.cache/swift-tc/usr/bin/swiftc" "/tmp/swift-tc/usr/bin/swiftc"; do
    if [ -n "$c" ] && [ -x "$c" ]; then SWIFTC="$c"; break; fi
  done
fi
if [ -z "$SWIFTC" ]; then
  echo "  ℹ️ لا يوجد مترجم Swift على هذا الجهاز — تخطّي فحص الصياغة (لن يفشل شيء)"
  exit 0
fi

echo "  المترجم: $("$SWIFTC" --version 2>&1 | head -1)"
FAIL=0

# ── ① فحص صياغة كل ملف ──
for f in *.swift Widget/*.swift; do
  [ -e "$f" ] || continue
  if ! out="$("$SWIFTC" -parse "$f" 2>&1)"; then
    echo "  ❌ صياغة $f:"
    echo "$out" | grep -E "error:" | head -5 | sed 's/^/     /'
    FAIL=1
  fi
done

# ── ② فحص كامل للملف المشترك (لا يستعمل واجهات أبل) ──
if ! out="$("$SWIFTC" -swift-version 5 -typecheck Shared.swift 2>&1)"; then
  echo "  ❌ Shared.swift — فحص كامل (تعريفات وأنواع):"
  echo "$out" | grep -E "error:" | head -10 | sed 's/^/     /'
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  N=$(ls *.swift Widget/*.swift 2>/dev/null | wc -l | tr -d ' ')
  echo "  ✔ صياغة $N ملفًا سليمة · Shared.swift فُحص فحصًا كاملًا"
fi
exit "$FAIL"
