import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testLaunchConnectsFlutterSceneAndRegistersPlugins() throws {
    let flutter_window = try XCTUnwrap(
      UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.rootViewController is FlutterViewController }
    )
    XCTAssertTrue(flutter_window.windowScene?.delegate is FlutterSceneDelegate)
    let flutter_controller = try XCTUnwrap(
      flutter_window.rootViewController as? FlutterViewController
    )
    let flutter_engine = try XCTUnwrap(flutter_controller.engine)
    for plugin_name in [
      "SharedPreferencesPlugin",
      "FlutterSecureStorageDarwinPlugin",
      "FLTFirebaseCorePlugin",
      "FLTFirebaseMessagingPlugin",
      "KakaoFlutterSdkCommonPlugin",
      "FlutterNaverLoginPlugin",
      "FLTGoogleSignInPlugin",
      "SignInWithApplePlugin",
    ] {
      XCTAssertTrue(flutter_engine.hasPlugin(plugin_name), "Missing plugin: \(plugin_name)")
    }
  }

}
