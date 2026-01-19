//
//  ContentView.swift
//  StepsTotalCaloriesWidget
//
//  Created by Stephanie Dugas on 1/15/26.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var healthStatusText: String = "Health access: Not enabled"
    @State private var stepsText: String = "—"
    @State private var caloriesText: String = "—"
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                Text("Steps + Total Calories")
                    .font(.largeTitle.bold())

                Text("This app powers a small Home Screen widget that shows your totals for today.")
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        StatusDot(isOn: healthStatusText.contains("Enabled"))
                        Text(healthStatusText)
                            .font(.headline)
                        Spacer()
                        if isLoading {
                            ProgressView()
                        }
                    }

                    HStack(spacing: 12) {
                        MetricCard(title: "Steps", value: stepsText)
                        MetricCard(title: "Total Calories", value: caloriesText)
                    }
                }

                Divider()

                VStack(spacing: 12) {
                    Button {
                        Task { await enableHealthAccess() }
                    } label: {
                        Text("Enable Health Access")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    Button {
                        Task { await refreshTotals(silent: false) }
                    } label: {
                        Text("Refresh Totals")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add the widget")
                            .font(.headline)

                        Text("Home Screen → long-press → Edit → Add Widget → “Steps + Total Calories”.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
            .task {
                // Optional: try loading on launch (won't prompt permissions)
                await refreshTotals(silent: true)
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func enableHealthAccess() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await HealthKitManager.shared.requestAuthorization()
            healthStatusText = "Health access: Enabled ✅"
            await refreshTotals(silent: true)
        } catch {
            healthStatusText = friendlyErrorText(error)
        }
    }

    @MainActor
    private func refreshTotals(silent: Bool) async {
        if !silent { isLoading = true }
        defer { if !silent { isLoading = false } }

        do {
            let totals = try await HealthKitManager.shared.fetchTodayTotals()
            stepsText = formatNumber(totals.steps)
            caloriesText = formatNumber(totals.totalCalories)

            if !healthStatusText.contains("Enabled") {
                healthStatusText = "Health access: Enabled ✅"
            }

            // Nudge the widget to refresh immediately
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            healthStatusText = friendlyErrorText(error)
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func friendlyErrorText(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()

        if msg.contains("not determined") || msg.contains("authorization") {
            return "Health access: Tap “Enable Health Access”"
        }
        if msg.contains("not available") {
            return "Health access: Not available on this device"
        }
        return "Error: \(error.localizedDescription)"
    }
}

// MARK: - Small UI helpers

private struct MetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct StatusDot: View {
    let isOn: Bool

    var body: some View {
        Circle()
            .frame(width: 10, height: 10)
            .foregroundStyle(isOn ? .green : .gray)
    }
}
