@testable import FluidVoice_Debug
import Foundation
import XCTest

final class WakeWordPhraseValidationTests: XCTestCase {
    func testPhraseIsTrimmedForVocabulary() {
        XCTAssertEqual(WakeWordPhrase.normalized("  Hey Fluid  "), "Hey Fluid")
    }
    func testTooShortPhraseRejected() {
        XCTAssertNil(WakeWordPhrase.validated("ok"))            // < 3 chars
        XCTAssertEqual(WakeWordPhrase.validated("Computer"), "Computer")
    }
}
