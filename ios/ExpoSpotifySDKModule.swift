import ExpoModulesCore
import SpotifyiOS

public class ExpoSpotifySDKModule: Module {

    public func definition() -> ModuleDefinition {

        let spotifySession = ExpoSpotifySessionManager.shared
        let spotifyAppRemote = ExpoSpotifyAppRemoteManager.shared

        Name("ExpoSpotifySDK")

        Function("isAvailable") {
            return spotifySession.spotifyAppInstalled()
        }

        Function("isAppRemoteConnected") {
           return spotifyAppRemote.isConnected
         }

        AsyncFunction("authenticateAsync") { (config: [String: Any], promise: Promise) in
            guard let scopes = config["scopes"] as? [String] else {
                promise.reject("INVALID_CONFIG", "Invalid SpotifyConfig object")
                return
            }

            let tokenSwapURL = config["tokenSwapURL"] as? String
            let tokenRefreshURL = config["tokenRefreshURL"] as? String

            spotifySession.authenticate(scopes: scopes, tokenSwapURL: tokenSwapURL, tokenRefreshURL: tokenRefreshURL).done { session in
                spotifyAppRemote.accessToken = session.accessToken
                promise.resolve([
                    "accessToken": session.accessToken,
                    "refreshToken": session.refreshToken,
                    "expirationDate": Int(session.expirationDate.timeIntervalSince1970 * 1000),
                    "scopes": SPTScopeSerializer.serializeScopes(session.scope)
                ])
            }.catch { error in
                promise.reject(error)
            }
        }

        AsyncFunction("authorizeAndPlayURIAsync") { (config: [String: Any], promise: Promise) in
           log.info("authorize and play URI async called")
           guard let uri = config["uri"] as? String else {
             promise.reject("MISSING_URI", "URI is required")
             return
           }

           spotifyAppRemote.authorizeAndPlayURI(uri: uri).done { success in
             promise.resolve([
               "success": success
             ])
           }.catch { error in
             log.error(error)
             promise.reject(error)
           }
         }
    }
}
