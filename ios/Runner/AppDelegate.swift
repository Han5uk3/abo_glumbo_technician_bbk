import Flutter
import UIKit
import Firebase
import FirebaseAuth
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps with the API key
    GMSServices.provideAPIKey("AIzaSyBl4RQBYM_v-u2Oik_ENyxcGxnvyZGxL2o")
    
    // Explicitly configure Firebase
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    
    // Configure Firebase Auth for phone verification
    // Set up the authentication UI delegate to handle phone verification
    if #available(iOS 13.0, *) {
      // Modern iOS versions handle reCAPTCHA automatically
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle URL schemes for Google Sign-In and reCAPTCHA
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
