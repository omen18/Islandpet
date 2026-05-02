//
//  StopFocusIntent.swift
//  IslandPet (Shared)
//
//  AppIntent invoked from the Dynamic Island expanded view. Lives in BOTH
//  the app target and the widget extension so the system can dispatch it.
//  When the user taps the Stop button on the island, the intent posts a
//  Darwin notification that the running app picks up to actually halt the
//  timer and end the activity.
//

import Foundation
import AppIntents
import ActivityKit

@available(iOS 17.0, *)
public struct StopFocusIntent: LiveActivityIntent {

    public static var title: LocalizedStringResource = "Stop Focus Session"
    public static var description: IntentDescription? = "Ends the active focus session early."
    public static var isDiscoverable: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        // End any running activities right away so the UI updates immediately.
        for activity in Activity<PetActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        // Tell the app (if foregrounded) to do the bookkeeping.
        DistributedNotificationCenter.default()
            .postNotificationName(Notification.Name("islandpet.stopFocus"),
                                  object: nil,
                                  userInfo: nil,
                                  options: .deliverImmediately)
        return .result()
    }
}
