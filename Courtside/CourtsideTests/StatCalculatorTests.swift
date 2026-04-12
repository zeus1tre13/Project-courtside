import Testing
import Foundation
@testable import Courtside

@Suite("StatCalculator Tests")
struct StatCalculatorTests {

    @Test("Percentage formatting")
    func formatPercentage() {
        #expect(StatCalculator.formatPercentage(0.5) == "50.0")
        #expect(StatCalculator.formatPercentage(1.0) == "100.0")
        #expect(StatCalculator.formatPercentage(nil) == "-")
        #expect(StatCalculator.formatPercentage(0.333) == "33.3")
    }

    @Test("Point values for stat types")
    func pointValues() {
        #expect(StatType.fieldGoalMade.pointValue == 2)
        #expect(StatType.threePointMade.pointValue == 3)
        #expect(StatType.freeThrowMade.pointValue == 1)
        #expect(StatType.fieldGoalMissed.pointValue == 0)
        #expect(StatType.assist.pointValue == 0)
    }

    @Test("Shot zone classification")
    func shotZoneRequirements() {
        #expect(StatType.fieldGoalMade.requiresShotZone == true)
        #expect(StatType.threePointMissed.requiresShotZone == true)
        #expect(StatType.freeThrowMade.requiresShotZone == false)
        #expect(StatType.assist.requiresShotZone == false)
        #expect(StatType.freeThrowMade.isFreeThrow == true)
    }

    @Test("Game format period labels")
    func periodLabels() {
        #expect(GameFormat.fourQuarters.periodLabel(for: 1) == "Q1")
        #expect(GameFormat.fourQuarters.periodLabel(for: 4) == "Q4")
        #expect(GameFormat.fourQuarters.periodLabel(for: 5) == "OT1")
        #expect(GameFormat.twoHalves.periodLabel(for: 1) == "H1")
        #expect(GameFormat.twoHalves.periodLabel(for: 2) == "H2")
        #expect(GameFormat.twoHalves.periodLabel(for: 3) == "OT1")
    }
}
