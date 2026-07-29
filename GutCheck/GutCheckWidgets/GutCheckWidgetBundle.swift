//
//  GutCheckWidgetBundle.swift
//  GutCheckWidgets
//
//  Entry point for the GutCheck widget extension.
//
//  ── Manual Xcode setup required ────────────────────────────────────────────
//  These source files were added without Xcode, so the widget target itself
//  still has to be created once by hand:
//
//   1. File ▸ New ▸ Target… ▸ Widget Extension, named "GutCheckWidgets".
//      Uncheck "Include Live Activity" and "Include Configuration Intent"
//      (this bundle already declares its own configuration).
//   2. Delete the template files Xcode generates and add the files in this
//      folder to the new target instead.
//   3. Add `Services/Widgets/WidgetDataStore.swift` (which lives in the app
//      folder) to the widget target's membership as well — it is the only
//      shared type, and it deliberately depends on Foundation alone.
//   4. Signing & Capabilities ▸ add the App Group `group.com.gutcheck.shared`
//      to BOTH the GutCheck app target and the GutCheckWidgets target.
//      `GutCheckWidgets.entitlements` and the app's entitlements files already
//      declare it; the group still has to exist on the developer account.
//   5. Set the widget target's deployment target to match the app.
//  ───────────────────────────────────────────────────────────────────────────
//

import SwiftUI
import WidgetKit

@main
struct GutCheckWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Free tier: the daily health score, home screen and lock screen.
        HealthScoreWidget()

        // Configurable single-metric widget (AppIntentConfiguration, iOS 17+).
        if #available(iOS 17.0, *) {
            GutCheckMetricWidget()
        }
    }
}
