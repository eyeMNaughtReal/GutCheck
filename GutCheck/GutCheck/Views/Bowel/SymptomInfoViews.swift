//
//  SymptomInfoViews.swift
//  GutCheck
//
//  Wrapper for presenting the correct symptom info view.
//

import SwiftUI

public struct SymptomInfoViews: View {
    public let infoType: SymptomInfoType
    public init(infoType: SymptomInfoType) {
        self.infoType = infoType
    }
    public var body: some View {
        switch infoType {
        case .bristol:
            BristolStoolInfoView()
        case .pain:
            PainLevelInfoView()
        case .urgency:
            UrgencyLevelInfoView()
        }
    }
}
