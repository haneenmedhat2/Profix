//
//  PushNotification.swift
//  Esterad
//
//  Created by Haneen on 27/10/2025.
//

import Foundation
import UIKit
import AVFoundation
import Firebase
import FirebaseMessaging

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "No Device token found")")
        UserDefaults.pushNotificationToken = fcmToken ?? "No Token Found"
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
    }
    
    //MARK: - Handel the arrived Notifications
    
    //Use this method to process incoming remote notifications for your app
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationCountManager.shared.refresh()

        print(userInfo)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    //when the notification arrives and the app is in foreground
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
                
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print("Notification info is: \n\(userInfo)")

        let targetValue = userInfo[AnyHashable(FCMValueKeys.type.rawValue)] as? String
        let notificationType = targetValue.flatMap(NotificationType.init(rawValue:))

        let isOrderNotification = notificationType?.isOrderNotification == true

        if isOrderNotification {
            OrderNotificationSoundPlayer.shared.play()
        }
        
        switch targetValue {
            case NotificationType.delegateAcceptDate.rawValue,
            NotificationType.delegateRefusedOrder.rawValue,
            NotificationType.delegateAcceptedOffer.rawValue,
            NotificationType.delegateCreatedInvoice.rawValue,
            NotificationType.delegateFinishedOrder.rawValue,
            NotificationType.delegateRefuseDate.rawValue,
            NotificationType.orderIntransit.rawValue,
            NotificationType.orderIsPaid.rawValue:
            NotificationCountManager.shared.refresh()

            let orderId = userInfo[AnyHashable(FCMValueKeys.orderId.rawValue)] as? String
            let dic = [FCMValueKeys.id.rawValue: orderId]
            
            NotificationCenter.default.post(name: .isOrderChanged, object: nil, userInfo: dic as [AnyHashable: Any])
            
//        case NotificationType.ticketReply.rawValue:
//            let ticketId = userInfo[AnyHashable(FCMValueKeys.ticketId.rawValue)] as? String
//            let dic = [FCMValueKeys.id.rawValue: ticketId]
//            NotificationCenter.default.post(name: .isComplaintsChanged, object: nil, userInfo: dic as [AnyHashable: Any])
            
            
        case NotificationType.blockNotify.rawValue,
            NotificationType.deleteNotify.rawValue:
            blockUser()
        default:
            break
        }
        let presentationOptions: UNNotificationPresentationOptions = isOrderNotification
            ? [.banner, .badge]
            : [.banner, .sound, .badge]
        completionHandler(presentationOptions)

    }
    
    // when the user tap on the notification banar
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        guard let targetValue = userInfo[AnyHashable(FCMValueKeys.type.rawValue)] as? String else {
            print("No target type found in notification ❌")
            return }
        
        guard let tabBar = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .flatMap({ $0.windows })
                  .first(where: { $0.isKeyWindow })?
                  .rootViewController as? AppTabBarController else { return }

        let notificationType = NotificationType(rawValue: targetValue)
        let orderId = userInfo[AnyHashable(FCMValueKeys.orderId.rawValue)] as? String
        let roomId = userInfo[AnyHashable(FCMValueKeys.roomId.rawValue)] as? String
        let ticketId = userInfo[AnyHashable(FCMValueKeys.ticketId.rawValue)] as? String

        switch notificationType {
        case  .delegateAcceptDate, /*.delegateAcceptedOffer,*/ .delegateCreatedInvoice, .delegateFinishedOrder,.delegateRefuseDate, .delegateRefusedOrder ,.orderIntransit , .scheduledOrderReminder , .scheduledOrderLateCancelFee , .scheduledOrderLateEditFee, .orderIsPaid:
            NotificationCountManager.shared.refresh()
            tabBar.routeToOrder(orderId?.toInt() ?? 0)

        case .blockNotify , .deleteNotify :
            blockUser()
        case .ticketReply , .ticketInprogress:
            tabBar.routeToTicket(ticketId?.toInt() ?? 0)
            
        case .newMessage:
            tabBar.routeToChat(roomId?.toInt() ?? 0)
            
        case .refundOrder:
            tabBar.routeToWallet()
            
        case .clientUpdated:
            tabBar.routeToProfile()

        default:
            guard UserDefaults.isLogin else {return}
            tabBar.routeToNotifications()
        }
        
        completionHandler()
    }
}

private final class OrderNotificationSoundPlayer {
    static let shared = OrderNotificationSoundPlayer()

    private var player: AVAudioPlayer?

    private init() {}

    func play() {
        guard let url = Bundle.main.url(forResource: "order_sound", withExtension: "caf") else {
            assertionFailure("Missing bundled order notification sound.")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Unable to play order notification sound: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Functions -

extension AppDelegate {
    
    private func getCurrentTabBar() -> AppTabBarController? {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let tabBar = window?.rootViewController as? AppTabBarController else { return nil}
        return tabBar
    }
    
    private func currentNavigationRootVC() -> BaseNav? {
        guard let tabBar = getCurrentTabBar() else { return nil }
        return tabBar.viewControllers?.first as? BaseNav
    }
    
    private func goTo(vc: UIViewController) {
        let window = SceneDelegate.current?.window
        var rootVC = window?.rootViewController as? UITabBarController
        
        if rootVC == nil {
            AppHelper.changeWindowRoot(vc: AppTabBarController())
            rootVC = (SceneDelegate.current?.window?.rootViewController as? UITabBarController)
        }
        
        if let selectedIndex = rootVC?.selectedIndex {
            rootVC?.viewControllers?[selectedIndex].show(vc, sender: self)
        }
    }
    
    
    private func blockUser() {
        UserDefaults.isLogin = false
        UserDefaults.guest = true
        Session.token = nil
        Session.user = nil
        UserDefaults.notificationCount = 0
        let vc = SplashVC()
        AppHelper.changeWindowRoot(vc: vc, options: .transitionCurlDown)
    }
}

//MARK: - Routes -

extension AppDelegate {
        
    private func setNotificationTab() {
        guard let root = currentNavigationRootVC() else { return }
        if root.visibleViewController?.isKind(of: NotificationVC.self) == false {
            let vc = NotificationVC(viewModel: NotificationVM())
            root.pushViewController(vc, animated: true)
        }
    }
}
