//
//  TriggerPatternDetailViewModel.swift
//  GutCheck
//
//  ViewModel for the trigger pattern detail view.
//

import Foundation

@MainActor
@Observable class TriggerPatternDetailViewModel {
    var relatedPatterns: [TriggerPattern] = []

    func loadRelatedPatterns(for pattern: TriggerPattern, allPatterns: [TriggerPattern]) {
        let thisIngredients = Set(pattern.ingredientBreakdown.map { $0.ingredientName })
        relatedPatterns = allPatterns.filter { other in
            other.id != pattern.id &&
            !Set(other.ingredientBreakdown.map { $0.ingredientName })
                .intersection(thisIngredients).isEmpty
        }
    }
}
