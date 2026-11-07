import Testing
@testable import TranslateCore

@Suite struct LengthBudgetTests {
    @Test func rejectsAPromptOverTheInputLimit() {
        #expect(throws: TranslationError.inputTooLong(tokens: 2049, limit: 2048)) {
            try LengthBudget(promptTokens: 2049)
        }
    }

    @Test func allowsTwiceTheInputPlusSlackForTheOutput() throws {
        #expect(try LengthBudget(promptTokens: 10).output == 84)
        #expect(try LengthBudget(promptTokens: 2048).output == 4160)
    }

    @Test func promptAndOutputAlwaysFitTheContext() throws {
        for promptTokens in stride(from: 1, through: LengthBudget.inputLimit, by: 1) {
            let budget = try LengthBudget(promptTokens: promptTokens)
            #expect(promptTokens + budget.output < LengthBudget.contextSize)
        }
    }
}
