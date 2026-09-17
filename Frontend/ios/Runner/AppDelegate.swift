import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "com.cljstudio.umarket/notificaciones"
  private let shortcutChannelName = "com.cljstudio.umarket/atajo_venta_rapida"
  private let tokenKey = "umarket_apns_device_token"
  private var notificationChannel: FlutterMethodChannel?
  private var pendingRegistrationResult: FlutterResult?
  private var initialNotification: [AnyHashable: Any]?

  private var apnsEnvironment: String {
    // La configuración Release no determina por sí sola el servidor APNs.
    // Una app Release instalada desde Xcode puede seguir firmada con el
    // entitlement "development". El perfil incluido es la fuente real para
    // instalaciones directas; TestFlight cae correctamente en producción.
    if let profileURL = Bundle.main.url(
      forResource: "embedded",
      withExtension: "mobileprovision"
    ),
       let profileData = try? Data(contentsOf: profileURL) {
      let profile = String(decoding: profileData, as: UTF8.self)
      let key = "<key>aps-environment</key>"
      if let keyRange = profile.range(of: key),
         let startRange = profile.range(
           of: "<string>",
           range: keyRange.upperBound..<profile.endIndex
         ),
         let endRange = profile.range(
           of: "</string>",
           range: startRange.upperBound..<profile.endIndex
         ) {
        let value = String(profile[startRange.upperBound..<endRange.lowerBound])
        return value == "production" ? "production" : "sandbox"
      }
    }

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
    let iniciado = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    // Apple recomienda solicitar un token vigente en cada arranque. Esto no
    // muestra el diálogo de permisos; únicamente renueva la dirección APNs.
    application.registerForRemoteNotifications()
    return iniciado
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

    let shortcutChannel = FlutterMethodChannel(
      name: shortcutChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    shortcutChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "syncSession":
        guard let arguments = call.arguments as? [String: Any] else {
          result(FlutterError(
            code: "SHORTCUT_SESSION",
            message: "La sesión recibida no es válida.",
            details: nil
          ))
          return
        }
        do {
          try CredencialesAtajoVentaRapida.actualizar(
            accessToken: arguments["accessToken"] as? String,
            refreshToken: arguments["refreshToken"] as? String,
            userId: arguments["userId"] as? String
          )
          if #available(iOS 16.0, *) {
            AtajosUMarket.updateAppShortcutParameters()
          }
          result(true)
        } catch {
          result(FlutterError(
            code: "SHORTCUT_SESSION",
            message: error.localizedDescription,
            details: nil
          ))
        }
      case "latestSession":
        var session: [String: Any] = ["refreshToken": NSNull()]
        if let refreshToken = CredencialesAtajoVentaRapida.refreshToken {
          session["refreshToken"] = refreshToken
        }
        result(session)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func currentStatus(_ result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      // El callback de UNUserNotificationCenter puede llegar en segundo plano.
      // Toda lectura de UIApplication y la respuesta a Flutter deben ejecutarse
      // en el hilo principal para evitar bloqueos y tirones en iOS.
      DispatchQueue.main.async {
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
        result(response)
      }
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
