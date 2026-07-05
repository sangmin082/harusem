import Foundation
import UserNotifications

/// 데일리 리마인더 로컬 알림 (매일 아침 9시).
enum ReminderService {
    private static let identifier = "harusem.daily.reminder"

    /// 켜기: 권한 요청 후 반복 알림 등록. 권한 거부 시 false.
    /// 끄기: 등록된 알림 제거 후 true.
    static func setEnabled(_ enabled: Bool) async -> Bool {
        let center = UNUserNotificationCenter.current()
        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return true
        }

        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Today's Harusem is ready!")
        content.body = String(localized: "Five fresh puzzles are waiting.")
        content.sound = .default

        var time = DateComponents()
        time.hour = 9
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        )
        try? await center.add(request)
        return true
    }
}
