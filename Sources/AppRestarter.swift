//
//  AppRestarter.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 08/09/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Darwin
import UserNotifications

enum AppRestarter {
    private static let notificationIdentifier = "io.wedobooks.SampleApp.restart"
    
    static func closeAndOfferRelaunch(title: String, body: String) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("Notification authorization failed: \(error)")
            }
            guard granted else {
                exit(EXIT_SUCCESS)
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.userInfo = ["pushType": "restart"]

            let request = UNNotificationRequest(
                identifier: notificationIdentifier,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            )

            center.add(request) { error in
                if let error {
                    print("Scheduling the relaunch notification failed: \(error)")
                }
                exit(EXIT_SUCCESS)
            }
        }
    }

    static func clearRelaunchNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
    }
}
