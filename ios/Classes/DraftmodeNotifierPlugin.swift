import Flutter
import UIKit
import UserNotifications

public class DraftmodeNotifierPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    guard #available(iOS 10.0, *) else {
      return
    }

    guard
      let appDelegate = UIApplication.shared.delegate,
      let notificationDelegate = appDelegate as? UNUserNotificationCenterDelegate
    else {
      return
    }

    let center = UNUserNotificationCenter.current()
    if center.delegate !== notificationDelegate {
      center.delegate = notificationDelegate
    }
  }
}
