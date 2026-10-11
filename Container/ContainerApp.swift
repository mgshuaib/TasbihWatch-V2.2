//
//  ContainerApp.swift
//  سُبحة — تطبيق الحاوية (المسار «ب» فقط)
//
//  ⚠️ هذا التطبيق لا يعمل ولا يُشغّل إطلاقًا.
//  الغرض الوحيد منه: توفير حزمة iOS «حاملة» لتطبيق الساعة،
//  لأن أدوات أبل ترفض رفع تطبيق ساعة مستقل إلى App Store.
//  المفتاح LSApplicationLaunchProhibited=true في Info.plist يمنع تشغيله.
//

import SwiftUI

@main
struct ContainerApp: App {
    var body: some Scene {
        WindowGroup {
            Text("افتح التطبيق من ساعتك ⌚️")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
