@testable import FluidVoice_Debug
import Foundation
import XCTest

@MainActor
final class VoiceActivationSettingsTests: XCTestCase {
    private let keys = [
        "AutoStopEnabled", "AutoStopHangover", "MaxRecordingCapSeconds",
        "WakeWordEnabled", "WakeWordPhrase",
    ]

    override func setUp() {
        super.setUp()
        for k in keys { UserDefaults.standard.removeObject(forKey: k) }
    }
    override func tearDown() {
        for k in keys { UserDefaults.standard.removeObject(forKey: k) }
        super.tearDown()
    }

    func testDefaultsAreOff() {
        let s = SettingsStore.shared
        XCTAssertFalse(s.autoStopEnabled)
        XCTAssertFalse(s.wakeWordEnabled)
        XCTAssertEqual(s.autoStopHangover, .balanced)
        XCTAssertEqual(s.maxRecordingCapSeconds, 60)
        XCTAssertEqual(s.wakeWordPhrase, "Hey Fluid")
    }

    func testEnablingWakeWordForcesAutoStopOn() {
        let s = SettingsStore.shared
        s.autoStopEnabled = false
        s.wakeWordEnabled = true
        XCTAssertTrue(s.autoStopEnabled, "Enabling Tier C must coerce Tier A on")
        XCTAssertTrue(s.wakeWordEnabled)
    }

    func testDisablingAutoStopForcesWakeWordOff() {
        let s = SettingsStore.shared
        s.wakeWordEnabled = true   // also turns A on
        s.autoStopEnabled = false  // must drag C off
        XCTAssertFalse(s.wakeWordEnabled, "Disabling Tier A must coerce Tier C off")
        XCTAssertFalse(s.autoStopEnabled)
    }

    func testCapClampsToRange() {
        let s = SettingsStore.shared
        s.maxRecordingCapSeconds = 5
        XCTAssertEqual(s.maxRecordingCapSeconds, 20)
        s.maxRecordingCapSeconds = 9999
        XCTAssertEqual(s.maxRecordingCapSeconds, 180)
    }

    func testBlankPhraseFallsBackToDefault() {
        let s = SettingsStore.shared
        s.wakeWordPhrase = "   "
        XCTAssertEqual(s.wakeWordPhrase, "Hey Fluid")
        s.wakeWordPhrase = "Computer"
        XCTAssertEqual(s.wakeWordPhrase, "Computer")
    }

    func testHangoverSeconds() {
        XCTAssertEqual(AutoStopHangoverPreset.snappy.silenceSeconds, 0.8, accuracy: 0.0001)
        XCTAssertEqual(AutoStopHangoverPreset.balanced.silenceSeconds, 1.2, accuracy: 0.0001)
        XCTAssertEqual(AutoStopHangoverPreset.relaxed.silenceSeconds, 1.8, accuracy: 0.0001)
    }
}
