import Testing
@testable import Translate

struct StructuredTextTests {
    @Test func listsBecomeMarkedLinesAndInlineMarkupDisappears() {
        let html = """
        <meta charset="utf-8"><ul><li>First <strong>bold</strong> item</li><li>Second with <a href="https://x.y">link</a><ul><li>Nested one</li></ul></li></ul><p>Para one.</p><p>Para two.</p><ol><li>Alpha</li><li>Beta</li></ol>
        """
        #expect(StructuredText.plain(fromHTML: html) == """
        • First bold item
        • Second with link
          ◦ Nested one
        Para one.
        Para two.
        1. Alpha
        2. Beta
        """)
    }

    @Test func plainParagraphsStayPlain() {
        #expect(StructuredText.plain(fromHTML: "<p>One.</p><p>Two.</p>") == "One.\nTwo.")
    }

    @Test func leadingIndentationSurvives() {
        #expect(StructuredText.plain(fromHTML: "<pre>    first\n\n    second\n</pre>") == "    first\n\n    second")
    }

    @Test func nothingReadableGivesNil() {
        #expect(StructuredText.plain(fromHTML: "") == nil)
        #expect(StructuredText.plain(fromHTML: "<p> </p>") == nil)
    }
}
