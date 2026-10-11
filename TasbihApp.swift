//
//  TasbihApp.swift
//  سبحة — نقطة الدخول
//

import SwiftUI

@main
struct TasbihApp: App {

    init() {
        #if DEBUG
        // 📸 لو شُغّل التطبيق لأخذ لقطات المتجر (انظر DebugShots.swift)
        SabhaShot.prepareIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            CounterView()
        }
    }
}
