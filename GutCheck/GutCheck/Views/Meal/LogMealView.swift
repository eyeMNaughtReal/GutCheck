import SwiftUI

struct LogMealView: View {
    @StateObject private var viewModel = LogMealViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Meal Name
                    TextField("Meal name", text: $viewModel.mealName)
                        .padding()
                        .background(ColorTheme.surface)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ColorTheme.border, lineWidth: 1)
                        )

                    // Meal Type Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meal Type")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)

                        Picker("Meal Type", selection: $viewModel.mealType) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Food Items List
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Food Items")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)

                        ForEach(viewModel.foodItems.indices, id: \.self) { index in
                            HStack {
                                TextField("Food Item", text: $viewModel.foodItems[index].name)
                                    .textFieldStyle(.roundedBorder)

                                Button(action: {
                                    viewModel.foodItems.remove(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(ColorTheme.error)
                                }
                            }
                        }

                        Button {
                            viewModel.foodItems.append(FoodItem(name: "", quantity: ""))

                        } label: {
                            Label("Add Food Item", systemImage: "plus.circle")
                                .foregroundColor(ColorTheme.primary)
                        }
                        .padding(.top, 4)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)

                        TextEditor(text: $viewModel.notes)
                            .frame(height: 100)
                            .padding(6)
                            .background(ColorTheme.surface)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(ColorTheme.border, lineWidth: 1)
                            )
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        CustomButton(
                            title: "Save Meal",
                            action: {
                                viewModel.saveMeal()
                                dismiss()
                            },
                            style: .primary,
                            isLoading: viewModel.isSaving
                        )
                        CustomButton(
                            title: "Cancel",
                            action: {
                                dismiss()
                            },
                            style: .outline
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Log Meal")
            .background(ColorTheme.background.ignoresSafeArea())
        }
    }
}

#Preview {
    LogMealView()
}
