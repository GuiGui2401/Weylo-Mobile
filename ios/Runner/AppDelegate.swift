import Flutter
import UIKit
import flutter_uploader

@main
@objc class AppDelegate: FlutterAppDelegate {
  private func registerPlugins(registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    FlutterUploaderPlugin.setPluginRegistrantCallback(registerPlugins)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    FlutterUploaderPlugin.handleEventsForBackgroundURLSession(
      identifier,
      completionHandler: completionHandler
    )
  }
}
