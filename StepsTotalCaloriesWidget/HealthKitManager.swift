//
//  HealthKitManager.swift
//  StepsTotalCaloriesWidget
//
//  Created by Stephanie Dugas on 1/19/26.
//

import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private init() {}

    private var stepsType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .stepCount)!
    }

    private var activeEnergyType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    }

    private var basalEnergyType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKit", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Health data is not available on this device."
            ])
        }

        let readTypes: Set<HKObjectType> = [stepsType, activeEnergyType, basalEnergyType]
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchTodayTotals() async throws -> (steps: Int, totalCalories: Int) {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKit", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Health data is not available on this device."
            ])
        }

        async let steps = fetchTodaySumInt(quantityType: stepsType, unit: .count())
        async let active = fetchTodaySumInt(quantityType: activeEnergyType, unit: .kilocalorie())
        async let basal  = fetchTodaySumInt(quantityType: basalEnergyType, unit: .kilocalorie())

        let (s, a, b) = try await (steps, active, basal)
        return (s, a + b)
    }

    private func fetchTodaySumInt(quantityType: HKQuantityType, unit: HKUnit) async throws -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: Int(value.rounded()))
            }

            self.store.execute(query)
        }
    }
}
