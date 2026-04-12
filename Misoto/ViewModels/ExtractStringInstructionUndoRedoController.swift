//
//  ExtractStringInstructionUndoRedoController.swift
//  Misoto
//
//  Debounced undo/redo + AI polish/generate for extract flows that use [String] instructions.
//  Subscriptions start only after `enableAfterExtraction` (post-extraction editing).
//

import Combine
import Foundation

// MARK: - Ingredient strings (aligned with UploadRecipeViewModel)

enum ExtractRecipeAIIngredientStrings {
    @MainActor
    static func stringsMatchingUploadRecipeViewModel(
        dishIngredients: [RecipeTextParser.IngredientItem],
        marinadeIngredients: [RecipeTextParser.IngredientItem],
        seasoningIngredients: [RecipeTextParser.IngredientItem],
        doughBatterFillingIngredients: [RecipeTextParser.IngredientItem],
        sauceIngredients: [RecipeTextParser.IngredientItem],
        toppingIngredients: [RecipeTextParser.IngredientItem],
        garnishIngredients: [RecipeTextParser.IngredientItem]
    ) -> [String] {
        let groups: [[RecipeTextParser.IngredientItem]] = [
            dishIngredients, marinadeIngredients, seasoningIngredients,
            doughBatterFillingIngredients, sauceIngredients, toppingIngredients, garnishIngredients
        ]
        return groups.flatMap { items in
            items.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }.map { item in
                var parts: [String] = []
                if !item.amount.isEmpty { parts.append(item.amount) }
                if !item.unit.isEmpty { parts.append(item.unit) }
                if !item.name.isEmpty { parts.append(item.name) }
                return parts.joined(separator: " ")
            }
        }
    }
}

// MARK: - Host

@MainActor
protocol ExtractStringInstructionUndoHost: AnyObject, ObservableObject {
    var description: String { get set }
    var tips: [String] { get set }
    var instructions: [String] { get set }
    var title: String { get }
    var isGeneratingDescription: Bool { get set }
    var isEditingInstructions: Bool { get set }
    var isTipsAILoading: Bool { get set }
    var errorMessage: String? { get set }
    var canUndoDescriptionAIEdit: Bool { get set }
    var canRedoDescriptionAIEdit: Bool { get set }
    var canUndoTipsAIEdit: Bool { get set }
    var canRedoTipsAIEdit: Bool { get set }
    var canUndoLastInstructionAIEdit: Bool { get set }
    var canRedoLastInstructionAIEdit: Bool { get set }

    var dishIngredients: [RecipeTextParser.IngredientItem] { get }
    var marinadeIngredients: [RecipeTextParser.IngredientItem] { get }
    var seasoningIngredients: [RecipeTextParser.IngredientItem] { get }
    var doughBatterFillingIngredients: [RecipeTextParser.IngredientItem] { get }
    var sauceIngredients: [RecipeTextParser.IngredientItem] { get }
    var toppingIngredients: [RecipeTextParser.IngredientItem] { get }
    var garnishIngredients: [RecipeTextParser.IngredientItem] { get }
}

// MARK: - Controller

@MainActor
final class ExtractStringInstructionUndoRedoController<Host: ExtractStringInstructionUndoHost> {
    private weak var host: Host?
    private var isEnabled = false
    private var subscriptionsAttached = false
    private var cancellables = Set<AnyCancellable>()

    private var instructionAIUndoStack: [[String]] = []
    private var instructionAIRedoStack: [[String]] = []
    private let maxInstructionAIUndoDepth = 30

    private var descriptionAIUndoStack: [String] = []
    private var descriptionAIRedoStack: [String] = []
    private let maxDescriptionAIUndoDepth = 30

    private var tipsAIUndoStack: [[String]] = []
    private var tipsAIRedoStack: [[String]] = []
    private let maxTipsAIUndoDepth = 30

    private let debouncedEditUndoDelayNanoseconds: UInt64 = 2_000_000_000

    private var descriptionUndoDebounceTask: Task<Void, Never>?
    private var descriptionCommitted: String = ""
    private var suppressDescriptionUndoScheduling = false

    private var tipsUndoDebounceTask: Task<Void, Never>?
    private var tipsCommitted: [String] = []
    private var suppressTipsUndoScheduling = false

    private var instructionsUndoDebounceTask: Task<Void, Never>?
    private var instructionsCommitted: [String] = []
    private var suppressInstructionsUndoScheduling = false

    init() {}

    func enableAfterExtraction(
        host: Host,
        descriptionChanges: AnyPublisher<String, Never>,
        tipsChanges: AnyPublisher<[String], Never>,
        instructionsChanges: AnyPublisher<[String], Never>
    ) {
        self.host = host
        isEnabled = true
        syncAllCommitted(from: host)
        guard !subscriptionsAttached else { return }
        subscriptionsAttached = true

        descriptionChanges
            .sink { [weak self] _ in
                guard let self, self.isEnabled else { return }
                guard !self.suppressDescriptionUndoScheduling else { return }
                self.scheduleDescriptionUndoCheckpoint()
            }
            .store(in: &cancellables)

        tipsChanges
            .sink { [weak self] _ in
                guard let self, self.isEnabled else { return }
                guard !self.suppressTipsUndoScheduling else { return }
                self.scheduleTipsUndoCheckpoint()
            }
            .store(in: &cancellables)

        instructionsChanges
            .sink { [weak self] _ in
                guard let self, self.isEnabled else { return }
                guard !self.suppressInstructionsUndoScheduling else { return }
                self.scheduleInstructionsUndoCheckpoint()
            }
            .store(in: &cancellables)
    }

    // MARK: - Description AI boundary (call from host `generateDescription` when enabled)

    func recordDescriptionSnapshotBeforeAIReplaceIfEnabled() {
        guard isEnabled, let host else { return }
        descriptionUndoDebounceTask?.cancel()
        descriptionAIRedoStack.removeAll()
        host.canRedoDescriptionAIEdit = false
        pushDescriptionUndo(host.description)
        host.canUndoDescriptionAIEdit = !descriptionAIUndoStack.isEmpty
    }

    func syncDescriptionCommittedAfterAIReplaceIfEnabled() {
        guard isEnabled, let host else { return }
        descriptionCommitted = host.description
    }

    // MARK: - Public AI + undo (mirrors UploadRecipeViewModel)

    func polishDescriptionWithAI() async {
        guard let host, isEnabled else { return }
        guard !host.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            host.errorMessage = LocalizedString("Add description text to polish.", comment: "Need description text for polish")
            return
        }

        host.isGeneratingDescription = true
        host.errorMessage = nil

        do {
            let edited = try await RecipeInstructionAI.improveInstructionStrings([host.description])
            guard let polished = edited.first else { return }
            captureDescriptionSnapshotForUndo(host: host)
            host.description = polished
            descriptionCommitted = host.description
        } catch {
            host.errorMessage = String(format: LocalizedString("Failed to polish description: %@", comment: "AI description polish error"), error.localizedDescription)
        }

        host.isGeneratingDescription = false
    }

    func undoDescriptionAIEdit() {
        guard let host, isEnabled else { return }
        descriptionUndoDebounceTask?.cancel()
        guard let older = descriptionAIUndoStack.popLast() else { return }
        pushDescriptionRedo(host.description)
        suppressDescriptionUndoScheduling = true
        host.description = older
        descriptionCommitted = older
        suppressDescriptionUndoScheduling = false
        host.canUndoDescriptionAIEdit = !descriptionAIUndoStack.isEmpty
        host.canRedoDescriptionAIEdit = !descriptionAIRedoStack.isEmpty
    }

    func redoDescriptionAIEdit() {
        guard let host, isEnabled else { return }
        descriptionUndoDebounceTask?.cancel()
        guard let newer = descriptionAIRedoStack.popLast() else { return }
        pushDescriptionUndo(host.description)
        suppressDescriptionUndoScheduling = true
        host.description = newer
        descriptionCommitted = newer
        suppressDescriptionUndoScheduling = false
        host.canUndoDescriptionAIEdit = !descriptionAIUndoStack.isEmpty
        host.canRedoDescriptionAIEdit = !descriptionAIRedoStack.isEmpty
    }

    func polishTipsWithAI() async {
        guard let host, isEnabled else { return }
        tipsUndoDebounceTask?.cancel()
        let hasTip = host.tips.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard hasTip else {
            host.errorMessage = LocalizedString("Add at least one tip to polish.", comment: "Need tip text for polish")
            return
        }

        host.isTipsAILoading = true
        host.errorMessage = nil

        do {
            let edited = try await RecipeInstructionAI.improveInstructionStrings(host.tips)
            captureTipsSnapshotForUndo(host: host)
            suppressTipsUndoScheduling = true
            defer { suppressTipsUndoScheduling = false }
            for i in 0..<min(host.tips.count, edited.count) {
                host.tips[i] = edited[i]
            }
            tipsCommitted = copyTipsForUndo(host.tips)
        } catch {
            host.errorMessage = String(format: LocalizedString("Failed to polish tips: %@", comment: "AI tips polish error"), error.localizedDescription)
        }

        host.isTipsAILoading = false
    }

    func generateTipsWithOpenAI() async {
        guard let host, isEnabled else { return }
        tipsUndoDebounceTask?.cancel()
        guard !host.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            host.errorMessage = LocalizedString("Please enter a recipe title first", comment: "Title required for AI instructions")
            return
        }

        host.isTipsAILoading = true
        host.errorMessage = nil

        do {
            let generated = try await OpenAIService.generateRecipeTips(
                title: host.title,
                ingredients: ingredientStrings(from: host),
                instructions: instructionTextsForAI(host: host),
                description: host.description
            )
            guard !generated.isEmpty else {
                host.errorMessage = LocalizedString("No tips were generated. Try adding more recipe detail.", comment: "AI tips empty result")
                host.isTipsAILoading = false
                return
            }
            captureTipsSnapshotForUndo(host: host)
            host.tips = generated
            tipsCommitted = copyTipsForUndo(host.tips)
        } catch {
            host.errorMessage = String(format: LocalizedString("Failed to generate tips: %@", comment: "AI tips generation error"), error.localizedDescription)
        }

        host.isTipsAILoading = false
    }

    func undoTipsAIEdit() {
        guard let host, isEnabled else { return }
        tipsUndoDebounceTask?.cancel()
        guard let older = tipsAIUndoStack.popLast() else { return }
        pushTipsRedo(copyTipsForUndo(host.tips))
        suppressTipsUndoScheduling = true
        host.tips = copyTipsForUndo(older)
        tipsCommitted = copyTipsForUndo(host.tips)
        suppressTipsUndoScheduling = false
        host.canUndoTipsAIEdit = !tipsAIUndoStack.isEmpty
        host.canRedoTipsAIEdit = !tipsAIRedoStack.isEmpty
    }

    func redoTipsAIEdit() {
        guard let host, isEnabled else { return }
        tipsUndoDebounceTask?.cancel()
        guard let newer = tipsAIRedoStack.popLast() else { return }
        pushTipsUndo(copyTipsForUndo(host.tips))
        suppressTipsUndoScheduling = true
        host.tips = copyTipsForUndo(newer)
        tipsCommitted = copyTipsForUndo(host.tips)
        suppressTipsUndoScheduling = false
        host.canUndoTipsAIEdit = !tipsAIUndoStack.isEmpty
        host.canRedoTipsAIEdit = !tipsAIRedoStack.isEmpty
    }

    func improveInstructionsWithAI() async {
        guard let host, isEnabled else { return }
        instructionsUndoDebounceTask?.cancel()
        let validInstructions = host.instructions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !validInstructions.isEmpty else {
            host.errorMessage = LocalizedString("Add at least one instruction step to polish.", comment: "Need instruction text for polish action")
            return
        }

        host.isEditingInstructions = true
        host.errorMessage = nil

        do {
            let editedTexts = try await RecipeInstructionAI.improveInstructionStrings(host.instructions)
            captureInstructionsSnapshotForUndo(host: host)
            suppressInstructionsUndoScheduling = true
            defer { suppressInstructionsUndoScheduling = false }
            for i in 0..<min(host.instructions.count, editedTexts.count) {
                host.instructions[i] = editedTexts[i]
            }
            instructionsCommitted = copyStringInstructions(host.instructions)
        } catch {
            host.errorMessage = String(format: LocalizedString("Failed to polish instructions: %@", comment: "AI instruction polish error"), error.localizedDescription)
        }

        host.isEditingInstructions = false
    }

    func generateInstructionsWithOpenAI() async {
        guard let host, isEnabled else { return }
        instructionsUndoDebounceTask?.cancel()
        guard !host.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            host.errorMessage = LocalizedString("Please enter a recipe title first", comment: "Title required for AI instructions")
            return
        }

        host.isEditingInstructions = true
        host.errorMessage = nil

        do {
            let generatedSteps = try await RecipeInstructionAI.generateInstructionStrings(
                title: host.title,
                ingredients: ingredientStrings(from: host)
            )

            captureInstructionsSnapshotForUndo(host: host)
            host.instructions = generatedSteps
            instructionsCommitted = copyStringInstructions(host.instructions)
        } catch {
            host.errorMessage = LocalizedString("Failed to generate instructions: \(error.localizedDescription)", comment: "AI instruction generation error")
        }

        host.isEditingInstructions = false
    }

    func undoLastInstructionAIEdit() {
        guard let host, isEnabled else { return }
        instructionsUndoDebounceTask?.cancel()
        guard let older = instructionAIUndoStack.popLast() else { return }
        pushInstructionRedo(copyStringInstructions(host.instructions))
        suppressInstructionsUndoScheduling = true
        host.instructions = copyStringInstructions(older)
        instructionsCommitted = copyStringInstructions(host.instructions)
        suppressInstructionsUndoScheduling = false
        host.canUndoLastInstructionAIEdit = !instructionAIUndoStack.isEmpty
        host.canRedoLastInstructionAIEdit = !instructionAIRedoStack.isEmpty
    }

    func redoLastInstructionAIEdit() {
        guard let host, isEnabled else { return }
        instructionsUndoDebounceTask?.cancel()
        guard let newer = instructionAIRedoStack.popLast() else { return }
        pushInstructionUndo(copyStringInstructions(host.instructions))
        suppressInstructionsUndoScheduling = true
        host.instructions = copyStringInstructions(newer)
        instructionsCommitted = copyStringInstructions(host.instructions)
        suppressInstructionsUndoScheduling = false
        host.canUndoLastInstructionAIEdit = !instructionAIUndoStack.isEmpty
        host.canRedoLastInstructionAIEdit = !instructionAIRedoStack.isEmpty
    }

    // MARK: - Private

    private func ingredientStrings(from host: Host) -> [String] {
        ExtractRecipeAIIngredientStrings.stringsMatchingUploadRecipeViewModel(
            dishIngredients: host.dishIngredients,
            marinadeIngredients: host.marinadeIngredients,
            seasoningIngredients: host.seasoningIngredients,
            doughBatterFillingIngredients: host.doughBatterFillingIngredients,
            sauceIngredients: host.sauceIngredients,
            toppingIngredients: host.toppingIngredients,
            garnishIngredients: host.garnishIngredients
        )
    }

    private func instructionTextsForAI(host: Host) -> [String] {
        host.instructions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func syncAllCommitted(from host: Host) {
        descriptionCommitted = host.description
        tipsCommitted = copyTipsForUndo(host.tips)
        instructionsCommitted = copyStringInstructions(host.instructions)
    }

    private func scheduleDescriptionUndoCheckpoint() {
        descriptionUndoDebounceTask?.cancel()
        descriptionUndoDebounceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.debouncedEditUndoDelayNanoseconds)
            guard !Task.isCancelled else { return }
            guard let host = self.host else { return }
            self.flushDescriptionUndoCheckpointIfNeeded(host: host)
        }
    }

    private func flushDescriptionUndoCheckpointIfNeeded(host: Host) {
        guard !suppressDescriptionUndoScheduling else { return }
        guard host.description != descriptionCommitted else { return }
        descriptionAIRedoStack.removeAll()
        host.canRedoDescriptionAIEdit = false
        pushDescriptionUndo(descriptionCommitted)
        descriptionCommitted = host.description
        host.canUndoDescriptionAIEdit = !descriptionAIUndoStack.isEmpty
    }

    private func scheduleTipsUndoCheckpoint() {
        tipsUndoDebounceTask?.cancel()
        tipsUndoDebounceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.debouncedEditUndoDelayNanoseconds)
            guard !Task.isCancelled else { return }
            guard let host = self.host else { return }
            self.flushTipsUndoCheckpointIfNeeded(host: host)
        }
    }

    private func flushTipsUndoCheckpointIfNeeded(host: Host) {
        guard !suppressTipsUndoScheduling else { return }
        guard host.tips != tipsCommitted else { return }
        tipsAIRedoStack.removeAll()
        host.canRedoTipsAIEdit = false
        pushTipsUndo(tipsCommitted)
        tipsCommitted = copyTipsForUndo(host.tips)
        host.canUndoTipsAIEdit = !tipsAIUndoStack.isEmpty
    }

    private func scheduleInstructionsUndoCheckpoint() {
        instructionsUndoDebounceTask?.cancel()
        instructionsUndoDebounceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.debouncedEditUndoDelayNanoseconds)
            guard !Task.isCancelled else { return }
            guard let host = self.host else { return }
            self.flushInstructionsUndoCheckpointIfNeeded(host: host)
        }
    }

    private func flushInstructionsUndoCheckpointIfNeeded(host: Host) {
        guard !suppressInstructionsUndoScheduling else { return }
        let current = copyStringInstructions(host.instructions)
        guard current != instructionsCommitted else { return }
        instructionAIRedoStack.removeAll()
        host.canRedoLastInstructionAIEdit = false
        pushInstructionUndo(instructionsCommitted)
        instructionsCommitted = current
        host.canUndoLastInstructionAIEdit = !instructionAIUndoStack.isEmpty
    }

    private func captureDescriptionSnapshotForUndo(host: Host) {
        descriptionUndoDebounceTask?.cancel()
        descriptionAIRedoStack.removeAll()
        host.canRedoDescriptionAIEdit = false
        pushDescriptionUndo(host.description)
        host.canUndoDescriptionAIEdit = true
    }

    private func pushDescriptionUndo(_ snapshot: String) {
        descriptionAIUndoStack.append(snapshot)
        if descriptionAIUndoStack.count > maxDescriptionAIUndoDepth {
            descriptionAIUndoStack.removeFirst(descriptionAIUndoStack.count - maxDescriptionAIUndoDepth)
        }
    }

    private func pushDescriptionRedo(_ snapshot: String) {
        descriptionAIRedoStack.append(snapshot)
        if descriptionAIRedoStack.count > maxDescriptionAIUndoDepth {
            descriptionAIRedoStack.removeFirst(descriptionAIRedoStack.count - maxDescriptionAIUndoDepth)
        }
    }

    private func captureTipsSnapshotForUndo(host: Host) {
        tipsUndoDebounceTask?.cancel()
        tipsAIRedoStack.removeAll()
        host.canRedoTipsAIEdit = false
        pushTipsUndo(copyTipsForUndo(host.tips))
        host.canUndoTipsAIEdit = true
    }

    private func pushTipsUndo(_ snapshot: [String]) {
        tipsAIUndoStack.append(snapshot)
        if tipsAIUndoStack.count > maxTipsAIUndoDepth {
            tipsAIUndoStack.removeFirst(tipsAIUndoStack.count - maxTipsAIUndoDepth)
        }
    }

    private func pushTipsRedo(_ snapshot: [String]) {
        tipsAIRedoStack.append(snapshot)
        if tipsAIRedoStack.count > maxTipsAIUndoDepth {
            tipsAIRedoStack.removeFirst(tipsAIRedoStack.count - maxTipsAIUndoDepth)
        }
    }

    private func copyTipsForUndo(_ items: [String]) -> [String] {
        Array(items)
    }

    private func captureInstructionsSnapshotForUndo(host: Host) {
        instructionsUndoDebounceTask?.cancel()
        instructionAIRedoStack.removeAll()
        host.canRedoLastInstructionAIEdit = false
        pushInstructionUndo(copyStringInstructions(host.instructions))
        host.canUndoLastInstructionAIEdit = true
    }

    private func pushInstructionUndo(_ snapshot: [String]) {
        instructionAIUndoStack.append(snapshot)
        if instructionAIUndoStack.count > maxInstructionAIUndoDepth {
            instructionAIUndoStack.removeFirst(instructionAIUndoStack.count - maxInstructionAIUndoDepth)
        }
    }

    private func pushInstructionRedo(_ snapshot: [String]) {
        instructionAIRedoStack.append(snapshot)
        if instructionAIRedoStack.count > maxInstructionAIUndoDepth {
            instructionAIRedoStack.removeFirst(instructionAIRedoStack.count - maxInstructionAIUndoDepth)
        }
    }

    private func copyStringInstructions(_ items: [String]) -> [String] {
        Array(items)
    }
}
