//
//  StepsTotalCaloriesWidget.swift
//  StepsTotalCaloriesWidget
//
//  Created by Stephanie Dugas on 1/19/26.
//

import WidgetKit
import SwiftUI

struct HealthEntry: TimelineEntry {
    let date: Date
    let steps: Int?
    let totalCalories: Int?
    let showEnableMessage: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HealthEntry {
        HealthEntry(date: Date(), steps: 8421, totalCalories: 2134, showEnableMessage: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (HealthEntry) -> Void) {
        completion(HealthEntry(date: Date(), steps: 8421, totalCalories: 2134, showEnableMessage: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthEntry>) -> Void) {
        Task {
            let entry: HealthEntry

            do {
                let totals = try await HealthKitManager.shared.fetchTodayTotals()
                entry = HealthEntry(date: Date(),
                                    steps: totals.steps,
                                    totalCalories: totals.totalCalories,
                                    showEnableMessage: false)
            } catch {
                entry = HealthEntry(date: Date(),
                                    steps: nil,
                                    totalCalories: nil,
                                    showEnableMessage: true)
            }

            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }
}

struct StepsTotalCaloriesWidgetView: View {
    let entry: Provider.Entry

    var body: some View {
        if entry.showEnableMessage {
            VStack(alignment: .leading, spacing: 8) {
                Text("Steps + Total Calories")
                    .font(.headline)

                Text("Open the app to enable Health access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                MetricRow(title: "Steps", value: entry.steps ?? 0)
                MetricRow(title: "Total Calories", value: entry.totalCalories ?? 0)

                Spacer(minLength: 0)
            }
            .padding()
        }
    }
}

private struct MetricRow: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(format(value))
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func format(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

struct StepsTotalCaloriesWidget: Widget {
    let kind: String = "StepsTotalCaloriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StepsTotalCaloriesWidgetView(entry: entry)
        }
        .configurationDisplayName("Steps + Total Calories")
        .description("Shows today’s totals from Apple Health.")
        .supportedFamilies([.systemSmall])
    }
}
