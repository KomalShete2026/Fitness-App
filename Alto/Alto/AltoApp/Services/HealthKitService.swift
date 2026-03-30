import Foundation
import HealthKit

protocol HealthKitService {
    var isAvailable: Bool { get }
    func requestPermissions() async throws
    func fetchLastNightSleepHours() async throws -> Double?
    func fetchActiveEnergyBurnedToday() async throws -> Double?
}

enum HealthKitServiceError: Error {
    case healthDataUnavailable
    case missingType
}

final class AppleHealthKitService: HealthKitService {
    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestPermissions() async throws {
        guard isAvailable else { throw HealthKitServiceError.healthDataUnavailable }

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let menstrualType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else {
            throw HealthKitServiceError.missingType
        }

        let readTypes: Set<HKObjectType> = [sleepType, hrvType, menstrualType]

        try await withCheckedThrowingContinuation { continuation in
            store.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: HealthKitServiceError.healthDataUnavailable)
                }
            }
        }
    }

    func fetchLastNightSleepHours() async throws -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitServiceError.missingType
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .hour, value: -12, to: startOfToday) ?? startOfToday
        let end = calendar.date(byAdding: .hour, value: 12, to: startOfToday) ?? now

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate, .strictEndDate])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let total = (samples as? [HKCategorySample])?
                    .filter { sample in
                        sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    }
                    .reduce(0.0) { partial, sample in
                        partial + sample.endDate.timeIntervalSince(sample.startDate)
                    } ?? 0

                if total <= 0 {
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: total / 3600.0)
                }
            }

            self.store.execute(query)
        }
    }

    func fetchActiveEnergyBurnedToday() async throws -> Double? {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitServiceError.missingType
        }

        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let kcal = result?.sumQuantity()?.doubleValue(for: .kilocalorie())
                continuation.resume(returning: kcal)
            }
            self.store.execute(query)
        }
    }
}
