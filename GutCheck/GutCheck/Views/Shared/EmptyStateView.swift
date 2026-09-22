import SwiftUI

/// The app's single empty state.
///
/// Wraps `ContentUnavailableView` so every "nothing here yet" state picks up
/// the platform's own metrics, spacing and Dynamic Type behaviour rather than
/// approximating them. The four hand-built versions this replaces used 40pt,
/// 48pt and 50pt glyphs for the same idea, all of them fixed sizes that did
/// not scale with the user's text size.
///
/// It draws no background of its own. These sit inside `List` rows and section
/// stacks that already supply a surface, and giving the empty state a second
/// rounded card is what produced the card-on-card look.
struct EmptyStateView<Actions: View>: View {
    let title: String
    let systemImage: String
    let description: String?
    @ViewBuilder let actions: () -> Actions

    init(
        title: String,
        systemImage: String,
        description: String? = nil,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actions = actions
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            if let description {
                Text(description)
            }
        } actions: {
            actions()
        }
    }
}

// Most empty states are informational and offer nothing to tap, so the common
// case gets an initialiser that omits the builder entirely.
extension EmptyStateView where Actions == EmptyView {
    init(title: String, systemImage: String, description: String? = nil) {
        self.init(title: title, systemImage: systemImage, description: description) {
            EmptyView()
        }
    }
}

#Preview("Description only") {
    EmptyStateView(
        title: "No meals logged",
        systemImage: "fork.knife",
        description: "Tap Log Meal below to get started"
    )
}

#Preview("With an action") {
    EmptyStateView(
        title: "No food items yet",
        systemImage: "fork.knife",
        description: "Add a food item to start building your meal."
    ) {
        Button("Add Food Item") {}
            .buttonStyle(.borderedProminent)
    }
}
