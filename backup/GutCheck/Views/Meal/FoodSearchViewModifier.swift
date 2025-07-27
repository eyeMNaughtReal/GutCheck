import SwiftUI

extension FoodSearchView {
    func onSelectFood(_ action: @escaping (FoodItem) -> Void) -> some View {
        var view = self
        view.onSelect = action
        return view
    }
}
