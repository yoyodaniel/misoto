//
//  ReportView.swift
//  Misoto
//
//  Created by Daniel Chan on 4.1.2026.
//

import SwiftUI

enum ReportType: Hashable {
    case recipe
    case user
    case both
}

enum ReportReason: String, CaseIterable {
    case spam = "Spam"
    case inappropriate = "Inappropriate Content"
    case harassment = "Harassment"
    case falseInformation = "False Information"
    case offensive = "Offensive Content"
    case sexualContent = "Sexual Content"
    case other = "Other"
    
    var localizedString: String {
        switch self {
        case .spam:
            return LocalizedString("Spam", comment: "Spam report reason")
        case .inappropriate:
            return LocalizedString("Inappropriate Content", comment: "Inappropriate content report reason")
        case .harassment:
            return LocalizedString("Harassment", comment: "Harassment report reason")
        case .falseInformation:
            return LocalizedString("False Information", comment: "False information report reason")
        case .offensive:
            return LocalizedString("Offensive Content", comment: "Offensive content report reason")
        case .sexualContent:
            return LocalizedString("Sexual Content", comment: "Sexual content report reason")
        case .other:
            return LocalizedString("Other", comment: "Other report reason")
        }
    }
}

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    let recipeID: String?
    let userID: String?
    
    @State private var selectedReportType: ReportType
    @State private var selectedReason: ReportReason?
    @State private var customReason: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    private let recipeReportService = RecipeReportService()
    private let userReportService = UserReportService()
    
    init(recipeID: String? = nil, userID: String? = nil) {
        self.recipeID = recipeID
        self.userID = userID
        // Default to reporting recipe if recipeID is provided, otherwise user
        self._selectedReportType = State(initialValue: recipeID != nil ? .recipe : .user)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Report Type Selection (only show if both recipeID and userID are available)
                if recipeID != nil && userID != nil {
                    Section {
                        Picker(LocalizedString("Report Type", comment: "Report type picker"), selection: $selectedReportType) {
                            Text(LocalizedString("Report Post", comment: "Report post option")).tag(ReportType.recipe)
                            Text(LocalizedString("Report User", comment: "Report user option")).tag(ReportType.user)
                            Text(LocalizedString("Report Both", comment: "Report both option")).tag(ReportType.both)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                Section {
                    Text(selectedReportType == .recipe 
                         ? LocalizedString("Why are you reporting this recipe?", comment: "Report recipe question")
                         : selectedReportType == .user
                         ? LocalizedString("Why are you reporting this user?", comment: "Report user question")
                         : LocalizedString("Why are you reporting this recipe and user?", comment: "Report both question"))
                        .font(.body)
                }
                
                Section {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button(action: {
                            HapticFeedback.buttonTap()
                            selectedReason = reason
                            if reason != .other {
                                customReason = ""
                            }
                        }) {
                            HStack {
                                Text(reason.localizedString)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                if selectedReason == .other {
                    Section {
                        TextField(LocalizedString("Please describe the issue", comment: "Custom reason placeholder"), text: $customReason, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(LocalizedString("Report", comment: "Report title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("Submit", comment: "Submit button")) {
                        HapticFeedback.importantAction()
                        Task {
                            await submitReport()
                        }
                    }
                    .disabled(isSubmitting || selectedReason == nil || (selectedReason == .other && customReason.trimmingCharacters(in: .whitespaces).isEmpty))
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
            .alert(LocalizedString("Report Submitted", comment: "Report success title"), isPresented: $showSuccessAlert) {
                Button(LocalizedString("OK", comment: "OK button")) {
                    dismiss()
                }
            } message: {
                Text(LocalizedString("Thank you for your report. We will review it shortly.", comment: "Report success message"))
            }
        }
    }
    
    private func submitReport() async {
        guard let reason = selectedReason else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        let reportReason = reason == .other ? customReason.trimmingCharacters(in: .whitespaces) : reason.rawValue
        
        do {
            switch selectedReportType {
            case .recipe:
                guard let recipeID = recipeID else {
                    errorMessage = LocalizedString("Recipe ID is missing", comment: "Missing recipe ID error")
                    isSubmitting = false
                    return
                }
                try await recipeReportService.reportRecipe(recipeID: recipeID, reason: reportReason)
            case .user:
                guard let userID = userID else {
                    errorMessage = LocalizedString("User ID is missing", comment: "Missing user ID error")
                    isSubmitting = false
                    return
                }
                try await userReportService.reportUser(userID: userID, reason: reportReason)
            case .both:
                guard let recipeID = recipeID, let userID = userID else {
                    errorMessage = LocalizedString("Recipe ID or User ID is missing", comment: "Missing ID error")
                    isSubmitting = false
                    return
                }
                // Report both recipe and user
                try await recipeReportService.reportRecipe(recipeID: recipeID, reason: reportReason)
                try await userReportService.reportUser(userID: userID, reason: reportReason)
            }
            
            HapticFeedback.play(.success)
            showSuccessAlert = true
        } catch {
            HapticFeedback.play(.error)
            errorMessage = error.localizedDescription
            print("⚠️ Error submitting report: \(error.localizedDescription)")
        }
        
        isSubmitting = false
    }
}

