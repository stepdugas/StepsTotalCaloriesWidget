//
//  StepsTotalCaloriesLiveActivity.swift
//  StepsTotalCalories
//
//  Created by Stephanie Dugas on 1/15/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StepsTotalCaloriesAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct StepsTotalCaloriesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StepsTotalCaloriesAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension StepsTotalCaloriesAttributes {
    fileprivate static var preview: StepsTotalCaloriesAttributes {
        StepsTotalCaloriesAttributes(name: "World")
    }
}

extension StepsTotalCaloriesAttributes.ContentState {
    fileprivate static var smiley: StepsTotalCaloriesAttributes.ContentState {
        StepsTotalCaloriesAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: StepsTotalCaloriesAttributes.ContentState {
         StepsTotalCaloriesAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: StepsTotalCaloriesAttributes.preview) {
   StepsTotalCaloriesLiveActivity()
} contentStates: {
    StepsTotalCaloriesAttributes.ContentState.smiley
    StepsTotalCaloriesAttributes.ContentState.starEyes
}
