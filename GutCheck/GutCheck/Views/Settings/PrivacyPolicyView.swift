import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: PolicySection?
    
    private let sections = PolicySection.allSections
    
    var body: some View {
        NavigationView {
            List {
                // Introduction Section
                Section {
                    Text("Last Updated: July 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("This Privacy Policy describes how GutCheck collects, uses, and protects your personal information.")
                        .font(.subheadline)
                }
                
                // Main Policy Sections
                ForEach(sections) { section in
                    NavigationLink(destination: PolicyDetailView(section: section)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title)
                                .font(.headline)
                            Text(section.summary)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Contact Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Questions or Concerns?")
                            .font(.headline)
                        Text("Contact us at privacy@gutcheck.app")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct PolicyDetailView: View {
    let section: PolicySection
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.title)
                        .font(.title2)
                        .bold()
                    
                    Text(section.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Section Content
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(section.details, id: \.title) { detail in
                        PolicyDetailSection(detail: detail)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PolicyDetailSection: View {
    let detail: PolicyDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(detail.title)
                .font(.headline)
            
            Text(detail.content)
                .font(.body)
                .foregroundColor(ColorTheme.text.opacity(0.8))
            
            if !detail.bullets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(detail.bullets, id: \.self) { bullet in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(bullet)
                        }
                        .font(.body)
                        .foregroundColor(ColorTheme.text.opacity(0.8))
                    }
                }
                .padding(.leading, 4)
            }
        }
        .padding()
        .roundedCard()
    }
}

// MARK: - Supporting Types

struct PolicySection: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let details: [PolicyDetail]
    
    static let allSections = [
        PolicySection(
            title: "Data Collection",
            summary: "Information we collect and how we collect it",
            details: [
                PolicyDetail(
                    title: "Personal Information",
                    content: "We collect personal information that you provide directly to us:",
                    bullets: [
                        "Name and contact information",
                        "Health and dietary information",
                        "Device and usage information"
                    ]
                ),
                PolicyDetail(
                    title: "Automatic Collection",
                    content: "We automatically collect certain information when you use our app:",
                    bullets: [
                        "Device identifiers",
                        "Usage patterns",
                        "Location data (if enabled)"
                    ]
                )
            ]
        ),
        PolicySection(
            title: "Data Usage",
            summary: "How we use your information",
            details: [
                PolicyDetail(
                    title: "Primary Uses",
                    content: "Your information helps us provide and improve our services:",
                    bullets: [
                        "Personalize your experience",
                        "Analyze patterns and trends",
                        "Improve app functionality",
                        "Send important updates"
                    ]
                )
            ]
        ),
        PolicySection(
            title: "Data Protection",
            summary: "How we protect your information",
            details: [
                PolicyDetail(
                    title: "Security Measures",
                    content: "We implement appropriate technical and organizational measures:",
                    bullets: [
                        "End-to-end encryption",
                        "Secure data storage",
                        "Regular security audits",
                        "Access controls"
                    ]
                )
            ]
        ),
        PolicySection(
            title: "Your Rights",
            summary: "Control over your information",
            details: [
                PolicyDetail(
                    title: "Data Rights",
                    content: "You have the following rights regarding your data:",
                    bullets: [
                        "Access your data",
                        "Request deletion",
                        "Export your data",
                        "Update your information"
                    ]
                )
            ]
        )
    ]
}

struct PolicyDetail {
    let title: String
    let content: String
    let bullets: [String]
}

#Preview {
    PrivacyPolicyView()
}
