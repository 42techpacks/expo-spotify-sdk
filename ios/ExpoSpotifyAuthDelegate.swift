import ExpoModulesCore
import SpotifyiOS

public class ExpoSpotifyAuthDelegate: ExpoAppDelegateSubscriber {
  let sessionManager = ExpoSpotifySessionManager.shared
  let appRemoteManager = ExpoSpotifyAppRemoteManager.shared

  public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    NSLog(url.absoluteString)

    //         First try to handle it with the app remote
    if let appRemote = appRemoteManager.appRemote,
       let authParams = appRemote.authorizationParameters(from: url) {

      // Extract access token if available
      if let accessToken = authParams[SPTAppRemoteAccessTokenKey] {
        NSLog("Got access token from app remote URL")
        appRemoteManager.accessToken = accessToken
        appRemote.connect()
        return true
      } else if let errorDescription = authParams[SPTAppRemoteErrorDescriptionKey] {
        NSLog("App remote authorization error: \(errorDescription)")
        return true
      }
    }

    // If app remote couldn't handle it, try the session manager
    if let canHandleURL = sessionManager.sessionManager?.application(app, open: url, options: options) {
      NSLog(canHandleURL ? "Session manager handled URL" : "Session manager could not handle URL")
      return canHandleURL
    }

    return false
  }
}


