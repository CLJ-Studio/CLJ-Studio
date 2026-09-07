import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "com.cljstudio.umarket/notificaciones"
  private let tokenKey = "umarket_apns_device_token"
  private var notificationChannel: FlutterMethodChannel?
  private var pendingRegistrationResult: FlutterResult?
  private var initialNotification: [AnyHashable: Any]?

  private var apnsEnvironment: String {
    #if DEBUG
      return "sandbox"
    #else
      return "production"
    #endif
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    initialNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any]
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    notificationChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "initialize", "status":
        self.currentStatus(result)
      case "requestPermissionAndRegister":
        self.requestPermissionAndRegister(result)
      case "disable":
        UIApplication.shared.unregisterForRemoteNotifications()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func currentStatus(_ result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let enabled = settings.authorizationStatus == .authorized
        || settings.authorizationStatus == .provisional
      let token = UserDefaults.standard.string(forKey: self.tokenKey)
      var response: [String: Any] = [
        "enabled": enabled,
        "registered": UIApplication.shared.isRegisteredForRemoteNotifications,
        "environment": self.apnsEnvironment,
      ]
      if let token { response["token"] = token }
      if let initial = self.initialNotification {
        response["initialPayload"] = self.serializablePayload(initial)
        self.initialNotification = nil
      }
      DispatchQueue.main.async { result(response) }
    }
  }

  private func requestPermissionAndRegister(_ result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      if let error {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "APNS_PERMISSION",
            message: error.localizedDescription,
            details: nil
          ))
        }
        return
      }
      guard granted else {
        DispatchQueue.main.async { result(["enabled": false]) }
        return
      }

      DispatchQueue.main.async {
        self.pendingRegistrationResult = result
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    UserDefaults.standard.set(token, forKey: tokenKey)
    let response: [String: Any] = [
      "enabled": true,
      "token": token,
      "environment": apnsEnvironment,
    ]
    pendingRegistrationResult?(response)
    pendingRegistrationResult = nil
    notificationChannel?.invokeMethod("tokenUpdated", arguments: response)
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    pendingRegistrationResult?(FlutterError(
      code: "APNS_REGISTRATION",
      message: error.localizedDescription,
      details: nil
    ))
    pendingRegistrationResult = nil
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let payload = serializablePayload(response.notification.request.content.userInfo)
    notificationChannel?.invokeMethod("notificationOpened", arguments: payload)
    completionHandler()
  }

  private func serializablePayload(_ payload: [AnyHashable: Any]) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in payload {
      guard let key = key as? String else { continue }
      if JSONSerialization.isValidJSONObject([key: value]) {
        result[key] = value
      }
    }
    return result
  }
}
