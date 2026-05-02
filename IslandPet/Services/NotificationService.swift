//
//  NotificationService.swift
//  IslandPet
//
//  Local notifications drive day-2+ retention. We schedule three classes:
//   1. Streak reminder  — "your pet misses you" at the user's typical study time
//      if no session has happened today by 8pm local.
//   2. Pet sadness ping — when hunger/happiness drops below threshold and the
//      app has been backgrounded for >12h.
//   3. Focus completion — fired by the timer ending while app is backgrounded.
//
//  All copy is written to feel like the *pet* talking, never the app.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    private let streakReminderID = "islandpet.streak.reminder"
    private let petSadID         = "islandpet.pet.sad"
    private let focusDoneID      = "islandpet.focus.complete"

    // MARK: - Permissions

    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Streak reminder (8pm local if no session today)

    func scheduleStreakReminderIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [streakReminderID])

        let petName = AppGroup.defaults?.string(forKey: "petName") ?? "your pet"
        let streak = AppGroup.defaults?.integer(forKey: "streak") ?? 0

        let content = UNMutableNotificationContent()
        if streak >= 3 {
            content.title = "Don't break the streak"
            content.body = "\(petName) is waiting. \(streak)-day streak on the line."
        } else {
            content.title = "\(petName) misses you"
            content.body = "Five minutes of focus and they'll be over the moon."
        }
        content.sound = .default
        content.threadIdentifier = "streak"
        content.interruptionLevel = .timeSensitive

        var date = DateComponents()
        date.hour = 20
        date.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)

        let request = UNNotificationRequest(
            identifier: streakReminderID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Pet sadness check

    func refreshPetSadnessReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [petSadID])

        guard let d = AppGroup.defaults else { return }
        let hunger = d.double(forKey: "hunger")
        let happiness = d.double(forKey: "happiness")
        let petName = d.string(forKey: "petName") ?? "your pet"

        // Only schedule if the pet is starting to suffer.
        guard hunger < 0.4 || happiness < 0.5 else { return }

        let content = UNMutableNotificationContent()
        if hunger < 0.3 {
            content.title = "\(petName) is hungry"
            content.body = "A quick check-in would mean the world."
        } else {
            content.title = "\(petName) feels lonely"
            content.body = "One short focus session can turn the day around."
        }
        content.sound = .default
        content.threadIdentifier = "pet-care"

        // Fire ~6 hours from now, so we don't pester right after backgrounding.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 6 * 3600,
                                                         repeats: false)
        let request = UNNotificationRequest(
            identifier: petSadID, content: content, trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Focus completion

    func scheduleFocusCompletion(at date: Date, petName: String, xp: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [focusDoneID])

        let content = UNMutableNotificationContent()
        content.title = "Session complete"
        content.body = "\(petName) earned +\(xp) XP. 🎉"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval,
                                                         repeats: false)
        let request = UNNotificationRequest(
            identifier: focusDoneID, content: content, trigger: trigger
        )
        center.add(request)
    }

    func cancelFocusCompletion() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [focusDoneID])
    }
}
