import Foundation

enum HeightConverter {
    static func imperialToCentimeters(feet: Int, inches: Int) -> Double {
        let totalInches = (feet * 12) + inches
        return Double(totalInches) * 2.54
    }

    static func centimetersToImperial(_ centimeters: Int) -> (feet: Int, inches: Int) {
        let totalInches = Int(round(Double(centimeters) / 2.54))
        let feet = totalInches / 12
        let inches = totalInches % 12
        return (feet, inches)
    }
}
