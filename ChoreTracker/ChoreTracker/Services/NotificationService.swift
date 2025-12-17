//
//  NotificationService.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import UserNotifications

/// Service for managing local notifications for chore reminders
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Permission
    
    /// Requests notification permission
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    /// Checks if notification permission is granted
    func checkPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Scheduling
    
    /// Schedules a notification for a chore instance
    func scheduleNotification(for instance: ChoreInstance, reminderMinutesBefore: Int = 60) {
        guard let dueDate = instance.dueDate,
              let template = instance.template,
              let name = template.name else {
            return
        }
        
        let notificationDate = Calendar.current.date(byAdding: .minute, value: -reminderMinutesBefore, to: dueDate) ?? dueDate
        
        // Don't schedule if the reminder time has already passed
        guard notificationDate > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Chore Reminder"
        content.body = "\(name) is due soon"
        content.sound = .default
        content.badge = 1
        
        // Use instance ID as identifier so we can cancel it later
        let identifier = instance.id?.uuidString ?? UUID().uuidString
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancels notification for a chore instance
    func cancelNotification(for instance: ChoreInstance) {
        guard let identifier = instance.id?.uuidString else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Cancels all notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Schedules notifications for all pending chores
    func scheduleNotificationsForPendingChores(instances: [ChoreInstance], reminderMinutesBefore: Int = 60) {
        for instance in instances {
            if instance.status == "pending" {
                scheduleNotification(for: instance, reminderMinutesBefore: reminderMinutesBefore)
            }
        }
    }
}

