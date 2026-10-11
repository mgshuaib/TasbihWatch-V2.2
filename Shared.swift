//
//  Shared.swift
//  سبحة — النماذج والبيانات ومنطق العدّ المشترك
//
//  ✅ ملف مشترك بين التطبيق والودجت (أضِفه إلى الهدفين).
//

import Foundation

// MARK: - نموذج الذكر

struct Dhikr: Identifiable, Hashable {
    let id: String
    let text: String          // النص المعروض على الساعة (قصير)
    let target: Int           // العدد المطلوب — 0 تعني «بلا حد»
    let full: String?         // النص الكامل للأذكار الطويلة (آية الكرسي، سيد الاستغفار…)
}

// MARK: - مجموعة الأذكار

struct DhikrSet: Identifiable, Hashable {
    let id: String
    let title: String         // اسم المجموعة
    let symbol: String        // أيقونة SF Symbol
    let closeTitle: String    // عنوان رسالة الإغلاق عند إتمام المجموعة
    let closeDua: String      // الدعاء/الرسالة الختامية
    let items: [Dhikr]

    var totalCount: Int { items.reduce(0) { $0 + $1.target } }
}

// MARK: - المجموعات

/// ⚠️ ملاحظة مهمة: هذه نصوص أذكار مشهورة من «حصن المسلم» وأذكار الصلوات.
/// راجعها مع مصدر موثوق قبل النشر، ويمكنك تعديل أي مجموعة بحرية من هنا —
/// التطبيق كله يقرأ من هذه المصفوفة، بما فيه المحاكي.
let adhkarSets: [DhikrSet] = [

    // ① بعد الصلاة
    DhikrSet(
        id: "after_prayer",
        title: "أذكار بعد الصلاة",
        symbol: "figure.mind.and.body",
        closeTitle: "تمّت أذكار ما بعد الصلاة",
        closeDua: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ",
        items: [
            Dhikr(id: "istighfar", text: "أَسْتَغْفِرُ اللَّه", target: 3, full: nil),
            Dhikr(id: "salam", text: "اللَّهُمَّ أَنْتَ السَّلَامُ…", target: 1,
                  full: "اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ"),
            Dhikr(id: "kursi", text: "آيَةُ الْكُرْسِيّ", target: 1,
                  full: "اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ"),
            Dhikr(id: "subhan", text: "سُبْحَانَ اللَّه", target: 33, full: nil),
            Dhikr(id: "hamd", text: "الْحَمْدُ لِلَّه", target: 33, full: nil),
            Dhikr(id: "akbar", text: "اللَّهُ أَكْبَر", target: 33, full: "تسبيح فاطمة رضي الله عنها: سُبْحَانَ اللَّه (٣٣) · الْحَمْدُ لِلَّه (٣٣) · اللَّهُ أَكْبَر (٣٤)"),
            Dhikr(id: "tahlil", text: "لَا إِلَهَ إِلَّا اللَّه وَحْدَهُ…", target: 1,
                  full: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ\n\n(تمام المائة بعد التسبيح والتحميد والتكبير)")
        ]
    ),

    // ② أذكار الصباح
    DhikrSet(
        id: "morning",
        title: "أذكار الصباح",
        symbol: "sunrise",
        closeTitle: "أتممت أذكار الصباح",
        closeDua: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّه — بارك الله يومك",
        items: [
            Dhikr(id: "kursi", text: "آيَةُ الْكُرْسِيّ", target: 1,
                  full: "اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ"),
            Dhikr(id: "muawwidhat", text: "الْمُعَوِّذَات", target: 3,
                  full: "قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ\n\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ ۝ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ\n\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَهِ النَّاسِ ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ"),
            Dhikr(id: "asbahna", text: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّه", target: 1,
                  full: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ"),
            Dhikr(id: "bika", text: "اللَّهُمَّ بِكَ أَصْبَحْنَا", target: 1,
                  full: "اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ"),
            Dhikr(id: "sayyid", text: "سَيِّدُ الِاسْتِغْفَارِ", target: 1,
                  full: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ"),
            Dhikr(id: "afini", text: "اللَّهُمَّ عَافِنِي فِي بَدَنِي", target: 3,
                  full: "اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ"),
            Dhikr(id: "bismillah", text: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ…", target: 3,
                  full: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ"),
            Dhikr(id: "raditu", text: "رَضِيتُ بِاللَّهِ رَبًّا", target: 3,
                  full: "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا"),
            Dhikr(id: "subhan100", text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", target: 100, full: nil)
        ]
    ),

    // ③ أذكار المساء
    DhikrSet(
        id: "evening",
        title: "أذكار المساء",
        symbol: "moon.stars",
        closeTitle: "أتممت أذكار المساء",
        closeDua: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّه — أحسن الله مساءك",
        items: [
            Dhikr(id: "kursi", text: "آيَةُ الْكُرْسِيّ", target: 1,
                  full: "اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ"),
            Dhikr(id: "muawwidhat", text: "الْمُعَوِّذَات", target: 3,
                  full: "قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ\n\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ ۝ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ\n\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَهِ النَّاسِ ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ"),
            Dhikr(id: "amsayna", text: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّه", target: 1,
                  full: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا"),
            Dhikr(id: "bika", text: "اللَّهُمَّ بِكَ أَمْسَيْنَا", target: 1,
                  full: "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ"),
            Dhikr(id: "sayyid", text: "سَيِّدُ الِاسْتِغْفَارِ", target: 1,
                  full: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ"),
            Dhikr(id: "bismillah", text: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ…", target: 3,
                  full: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ"),
            Dhikr(id: "aishah", text: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ…", target: 1,
                  full: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَأَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ، وَأَعُوذُ بِكَ مِنَ الْجُبْنِ وَالْبُخْلِ، وَأَعُوذُ بِكَ مِنْ غَلَبَةِ الدَّيْنِ وَقَهْرِ الرِّجَالِ"),
            Dhikr(id: "subhan100", text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", target: 100, full: nil)
        ]
    ),

    // ④ أذكار النوم
    DhikrSet(
        id: "sleep",
        title: "أذكار النوم",
        symbol: "bed.double",
        closeTitle: "أتممت أذكار النوم",
        closeDua: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا — نومًا هنيئًا",
        items: [
            Dhikr(id: "kursi", text: "آيَةُ الْكُرْسِيّ", target: 1,
                  full: "اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ"),
            Dhikr(id: "muawwidhat", text: "الْمُعَوِّذَات مَعَ النَّفْث", target: 3,
                  full: "تُقرأ الفاتحة والإخلاص والمعوذتان، ويُنفَث في الكفين ثم يُمسح بهما الوجه وما وصل من الجسد.\n\nقُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ"),
            Dhikr(id: "bismika", text: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا", target: 1, full: nil),
            Dhikr(id: "subhan", text: "سُبْحَانَ اللَّه", target: 33, full: nil),
            Dhikr(id: "hamd", text: "الْحَمْدُ لِلَّه", target: 33, full: nil),
            Dhikr(id: "akbar", text: "اللَّهُ أَكْبَر", target: 34,
                  full: "تسبيح فاطمة رضي الله عنها: سُبْحَانَ اللَّه (٣٣) · الْحَمْدُ لِلَّه (٣٣) · اللَّهُ أَكْبَر (٣٤)")
        ]
    ),

    // ⑤ أذكار متنوعة
    DhikrSet(
        id: "general",
        title: "أذكار متنوعة",
        symbol: "sparkles",
        closeTitle: "أتممت الأذكار المتنوعة",
        closeDua: "وَالْبَاقِيَاتُ الصَّالِحَاتُ خَيْرٌ عِنْدَ رَبِّكَ ثَوَابًا",
        items: [
            Dhikr(id: "subhan100", text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", target: 100, full: nil),
            Dhikr(id: "azim100", text: "سُبْحَانَ اللَّهِ الْعَظِيمِ", target: 100, full: nil),
            Dhikr(id: "tahlil100", text: "لَا إِلَهَ إِلَّا اللَّه وَحْدَهُ…", target: 100, full: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ\n\n(تمام المائة بعد التسبيح والتحميد والتكبير)"),
            Dhikr(id: "istighfar100", text: "أَسْتَغْفِرُ اللَّه وَأَتُوبُ إِلَيْهِ", target: 100, full: nil),
            Dhikr(id: "salah_nabi100", text: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّد", target: 100, full: nil),
            Dhikr(id: "hawla100", text: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّه", target: 100, full: nil)
        ]
    ),

    // ⑥ تسبيح مفتوح (بلا حد — للمستخدم الذي يريد العدّ بحرية)
    DhikrSet(
        id: "free",
        title: "تسبيح مفتوح",
        symbol: "infinity",
        closeTitle: "جلسة تسبيح",
        closeDua: "تقبّل الله ذكرك",
        items: [
            Dhikr(id: "subhan_free", text: "سُبْحَانَ اللَّه", target: 0, full: nil)
        ]
    ),
    // ⑦ الاستغفار
    DhikrSet(
        id: "istighfar",
        title: "الاستغفار",
        symbol: "arrow.triangle.2.circlepath",
        closeTitle: "تمّ الاستغفار",
        closeDua: "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ",
        items: [
            Dhikr(id: "istighfar_100", text: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ", target: 100, full: nil),
            Dhikr(id: "sayyid_alistighfar", text: "سَيِّدُ الِاسْتِغْفَار", target: 1,
                  full: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ"),
            Dhikr(id: "istighfar_33", text: "أَسْتَغْفِرُ اللَّهَ الْعَظِيم", target: 33, full: nil)
        ]
    ),

    // ⑧ الصلاة على النبي ﷺ
    DhikrSet(
        id: "salawat",
        title: "الصلاة على النبي ﷺ",
        symbol: "heart.fill",
        closeTitle: "صَلَّى اللَّهُ عَلَيْهِ وَسَلَّم",
        closeDua: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّد",
        items: [
            Dhikr(id: "salawat_100", text: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّد", target: 100, full: nil),
            Dhikr(id: "ibrahimiya", text: "الصَّلَاةُ الْإِبْرَاهِيمِيَّة", target: 1,
                  full: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، وَبَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ"),
            Dhikr(id: "salawat_33", text: "صَلَّى اللَّهُ عَلَيْهِ وَسَلَّم", target: 33, full: nil)
        ]
    )

]

// MARK: - مفاتيح التخزين

enum SharedKeys {
    static let setIndex   = "tasbih.setIndex"    // المجموعة الحالية
    static let itemIndex  = "tasbih.itemIndex"   // الذكر الحالي داخل المجموعة
    static let count      = "tasbih.count"       // عدد الذكر الحالي
    static let totalToday = "tasbih.totalToday"  // إجمالي اليوم
    static let day        = "tasbih.day"         // تاريخ آخر استخدام
    static let autoAdvance = "tasbih.autoAdvance"
    static let haptics     = "tasbih.haptics"
    static let setDone     = "tasbih.setDone"    // هل أُكملت المجموعة
    static let readMode    = "tasbih.readMode"   // وضع القراءة: النص كامل + عدّاد صغير في الزاوية
    static let fontScale   = "tasbih.fontScale"  // حجم الخط: 0 صغير · 1 متوسط · 2 كبير
    static let badgeRight  = "tasbih.badgeRight" // موضع العدّاد الصغير: يمين الشاشة؟
    static let autoScroll   = "tasbih.autoScroll"   // التمرير التلقائي (التلقين)
    static let scrollSpeed  = "tasbih.scrollSpeed"  // وتيرة التلقين بالكلمات/دقيقة
    static let distanceMode = "tasbih.distanceMode" // الرؤية من بعيد: خط أكبر وأسمك
    static let fontFamily   = "tasbih.fontFamily"   // خط القراءة (إن أُضيف للمشروع)
    static let nightMode    = "tasbih.nightMode"    // الوضع الليلي (من القائمة المنسدلة)
    static let countingMode     = "tasbih.countingMode"      // 0 النقرة المزدوجة · 1 حركة اليد · 2 التاج
    static let motionSensitivity = "tasbih.motionSensitivity" // حساسية كشف الحركة: 0/1/2
    static let bgOn         = "tasbih.bg.on"        // خلفية المجموعة
    static let bgOpacity    = "tasbih.bg.opacity"   // شدّة الخلفية (0.35 · 0.55 · 0.78)

    // ── الصوت والاهتزاز ──
    static let soundOn      = "tasbih.sound.on"      // نقرة صوتية ناعمة + نغمة إتمام
    static let hapticLevel  = "tasbih.haptic.level"  // شدة الاهتزاز: 0 ناعم · 1 متوسط · 2 قوي

    // ── الإحصاءات ──
    static let history      = "tasbih.history"       // { "YYYY-MM-DD": عدد } لآخر ٩٠ يومًا
    static let onboarded    = "tasbih.onboarded"     // هل رأى المستخدم شاشة الترحيب؟

    // ── إعدادات الودجت (يقرأها هدف الودجت) ──
    static let widgetMode       = "tasbih.widget.mode"        // 0 الذكر الحالي · 1 ملخّص المجموعة
    static let widgetShowsPlus  = "tasbih.widget.showsPlus"   // زر تسجيل داخل الودجت
    static let widgetShowsSet   = "tasbih.widget.showsSet"    // إظهار اسم المجموعة

    // ── آثار العدّ من الودجت (يكتبها الودجت ليقرأها التطبيق عند فتحه) ──
    static let lastAutoAdvanced  = "tasbih.widget.lastAutoAdvanced"   // رقم الذكر الذي انتقل إليه تلقائيًا
    static let lastSetCompleted  = "tasbih.widget.lastSetCompleted"   // هل اكتملت المجموعة من الودجت
}

// MARK: - التخزين المشترك

enum SharedDefaults {
    /// ⚠️ عدِّل المعرّف واجعله مطابقًا لـ App Group في الهدفين.
    static let appGroupID = "group.com.yourname.tasbih"

    static var store: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}

// MARK: - إعدادات الودجت (مشتركة بين التطبيق والودجت)

enum WidgetMode: Int {
    case current = 0     // الذكر الحالي + العدّاد + زر التسجيل
    case summary = 1     // ملخّص المجموعة: الاسم + الموضع + إجمالي اليوم
}

enum WidgetConfig {

    static var mode: WidgetMode {
        WidgetMode(rawValue: SharedDefaults.store.integer(forKey: SharedKeys.widgetMode)) ?? .current
    }

    static var showsPlus: Bool {
        let d = SharedDefaults.store
        return d.object(forKey: SharedKeys.widgetShowsPlus) as? Bool ?? true
    }

    static var showsSetName: Bool {
        let d = SharedDefaults.store
        return d.object(forKey: SharedKeys.widgetShowsSet) as? Bool ?? true
    }

    static func snapshot() -> (mode: WidgetMode, plus: Bool, set: Bool) {
        (mode, showsPlus, showsSetName)
    }
}

// MARK: - التاريخ

enum Day {
    static func key(_ date: Date = .now) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - 📊 سجلّ الإحصاءات (يوم بيوم)

/// قاموس {تاريخ : عدد} في مجموعة التطبيق — يُحدَّث من `SharedCounter.tap()`،
/// أي أن كل ذكر يُسجَّل من الساعة **أو من الودجت** يُحسب في يومه.
enum HistoryStore {

    static func all() -> [String: Int] {
        guard let data = SharedDefaults.store.data(forKey: SharedKeys.history),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return [:] }
        return dict
    }

    /// نحفظ آخر ٩٠ يومًا فقط (حتى لا يكبر التخزين بلا داعٍ)
    private static func save(_ dict: [String: Int]) {
        let keep = Set(dict.keys.sorted().suffix(90))
        let trimmed = dict.filter { keep.contains($0.key) }
        if let data = try? JSONEncoder().encode(trimmed) {
            SharedDefaults.store.set(data, forKey: SharedKeys.history)
        }
    }

    static func bump(_ by: Int = 1, on date: Date = .now) {
        guard by > 0 else { return }
        var dict = all()
        dict[Day.key(date), default: 0] += by
        save(dict)
    }

    static func count(on date: Date) -> Int { all()[Day.key(date)] ?? 0 }
    static func today() -> Int { count(on: .now) }
    static func totalAllTime() -> Int { all().values.reduce(0, +) }

    /// سلسلة الأيام المتتالية. إن لم تسجّل اليوم بعد نبدأ العدّ من أمس
    /// (حتى لا «تنكسر» السلسلة قبل أن تسبّح في اليوم الجديد).
    static func streak() -> Int {
        let dict = all()
        var date = Date.now
        if (dict[Day.key(date)] ?? 0) == 0 {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }
        var days = 0
        while (dict[Day.key(date)] ?? 0) > 0, days < 400 {
            days += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return days
    }

    /// آخر ٧ أيام، من الأقدم إلى اليوم (لأعمدة الإحصاءات)
    static func last7() -> [(label: String, count: Int, isToday: Bool)] {
        let names = ["أحد", "إثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت"]
        let dict = all()
        let cal = Calendar.current
        var out: [(label: String, count: Int, isToday: Bool)] = []
        for back in (0..<7).reversed() {
            let date = cal.date(byAdding: .day, value: -back, to: .now) ?? .now
            let weekday = cal.component(.weekday, from: date) - 1
            out.append((names[(weekday + 7) % 7], dict[Day.key(date)] ?? 0, back == 0))
        }
        return out
    }

    static func reset() { SharedDefaults.store.removeObject(forKey: SharedKeys.history) }
}

// MARK: - محرّك العدّ المشترك ⭐
//
//  هذا هو المصدر الوحيد للحقيقة: التطبيق والودجت كلاهما يقرأ ويكتب من هنا،
//  فتتزامن الحالة دائمًا بلا أي منطق مكرر.

enum StepEvent: Equatable {
    case counted            // زاد العدد فقط
    case advanced(Int)      // اكتمل الذكر وانتقل إلى الذكر التالي (رقم الذكر الجديد)
    case setCompleted       // اكتملت المجموعة كلها ✅
}

struct TasbihState: Equatable {
    var setIndex = 0
    var itemIndex = 0
    var count = 0
    var totalToday = 0
    var isSetDone = false
}

enum SharedCounter {

    // MARK: القراءة

    static func state() -> TasbihState {
        let d = SharedDefaults.store
        rollOverDayIfNeeded(d)
        var s = TasbihState()
        s.setIndex = clampSet(d.integer(forKey: SharedKeys.setIndex))
        s.itemIndex = clampItem(d.integer(forKey: SharedKeys.itemIndex), set: s.setIndex)
        s.count = max(0, d.integer(forKey: SharedKeys.count))
        s.totalToday = max(0, d.integer(forKey: SharedKeys.totalToday))
        s.isSetDone = d.bool(forKey: SharedKeys.setDone)
        return s
    }

    static func currentSet(_ s: TasbihState? = nil) -> DhikrSet {
        let st = s ?? state()
        return adhkarSets[clampSet(st.setIndex)]
    }

    static func currentDhikr(_ s: TasbihState? = nil) -> Dhikr {
        let st = s ?? state()
        let set = currentSet(st)
        return set.items[clampItem(st.itemIndex, set: st.setIndex)]
    }

    // MARK: الضغطة ⭐

    static func tap() -> StepEvent {
        let d = SharedDefaults.store
        rollOverDayIfNeeded(d)

        var st = state()
        if st.isSetDone { return .counted }   // المجموعة مكتملة: لا عدّ حتى يعيد المستخدم البدء

        let set = currentSet(st)
        let dhikr = set.items[clampItem(st.itemIndex, set: st.setIndex)]
        let unlimited = (dhikr.target <= 0)

        st.count += 1
        st.totalToday += 1
        HistoryStore.bump(1)      // 📊 سجلّ الإحصاءات (يُحسب عدّ الودجت أيضًا)

        defer { persist(d, st) }

        guard !unlimited, st.count >= dhikr.target else { return .counted }

        // اكتمل الذكر الحالي
        if st.itemIndex + 1 < set.items.count {
            st.itemIndex += 1
            st.count = 0
            return .advanced(st.itemIndex)      // انتقال سلس للذكر التالي
        }

        // كان آخر ذكر في المجموعة → المجموعة تمّت
        st.isSetDone = true
        return .setCompleted
    }

    // MARK: أوامر أخرى

    static func decrement() {
        let d = SharedDefaults.store
        var st = state()
        guard !st.isSetDone, st.count > 0 else { return }
        st.count -= 1
        if st.totalToday > 0 { st.totalToday -= 1 }
        persist(d, st)
    }

    static func resetCurrent() {
        let d = SharedDefaults.store
        var st = state()
        st.count = 0
        st.isSetDone = false
        persist(d, st)
    }

    /// إعادة المجموعة من أولها
    static func restartSet() {
        let d = SharedDefaults.store
        var st = state()
        st.itemIndex = 0
        st.count = 0
        st.isSetDone = false
        persist(d, st)
    }

    /// اختيار مجموعة جديدة
    static func selectSet(_ index: Int) {
        let d = SharedDefaults.store
        var st = state()
        st.setIndex = clampSet(index)
        st.itemIndex = 0
        st.count = 0
        st.isSetDone = false
        persist(d, st)
    }

    /// الانتقال اليدوي للذكر التالي (زر «التالي»)
    static func skipToNext() -> StepEvent {
        let d = SharedDefaults.store
        var st = state()
        let set = currentSet(st)
        guard !st.isSetDone else { return .counted }
        if st.itemIndex + 1 < set.items.count {
            st.itemIndex += 1
            st.count = 0
            persist(d, st)
            return .advanced(st.itemIndex)
        }
        st.isSetDone = true
        persist(d, st)
        return .setCompleted
    }

    // MARK: أدوات داخلية

    private static func persist(_ d: UserDefaults, _ st: TasbihState) {
        d.set(st.setIndex,   forKey: SharedKeys.setIndex)
        d.set(st.itemIndex,  forKey: SharedKeys.itemIndex)
        d.set(st.count,      forKey: SharedKeys.count)
        d.set(st.totalToday, forKey: SharedKeys.totalToday)
        d.set(st.isSetDone,  forKey: SharedKeys.setDone)
    }

    private static func rollOverDayIfNeeded(_ d: UserDefaults) {
        if d.string(forKey: SharedKeys.day) != Day.key() {
            d.set(Day.key(), forKey: SharedKeys.day)
            d.set(0, forKey: SharedKeys.totalToday)
        }
    }

    private static func clampSet(_ i: Int) -> Int { min(max(0, i), adhkarSets.count - 1) }

    private static func clampItem(_ i: Int, set: Int) -> Int {
        let n = adhkarSets[clampSet(set)].items.count
        return min(max(0, i), n - 1)
    }
}
