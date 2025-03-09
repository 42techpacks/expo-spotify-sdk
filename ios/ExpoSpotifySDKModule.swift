import ExpoModulesCore
import SpotifyiOS

let APP_REMOTE_CONNECTED_EVENT_NAME = "onAppRemoteConnected"
let APP_REMOTE_DISCONNECTED_EVENT_NAME = "onAppRemoteDisconnected"
let APP_REMOTE_CONNECTION_FAILED_EVENT_NAME = "onAppRemoteConnectionFailure"
let PLAYER_STATE_CHANGED_EVENT_NAME = "onPlayerStateChanged"

public class ExpoSpotifySDKModule: Module {

    public func definition() -> ModuleDefinition {

        let spotifySession = ExpoSpotifySessionManager.shared
        let spotifyAppRemote = ExpoSpotifyAppRemoteManager.shared

        OnCreate {
            NSLog("ExpoSpotifySDKModule created")
            spotifyAppRemote.module = self
        }

        OnDestroy {
            NSLog("ExpoSpotifySDKModule destroyed")
            spotifyAppRemote.module = nil
        }

        Name("ExpoSpotifySDK")
        Events(APP_REMOTE_CONNECTED_EVENT_NAME, APP_REMOTE_DISCONNECTED_EVENT_NAME, APP_REMOTE_CONNECTION_FAILED_EVENT_NAME, PLAYER_STATE_CHANGED_EVENT_NAME)

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

        AsyncFunction("connectAppRemoteAsync") { (config: [String: Any], promise: Promise) in
          log.info("connect app remote async called")
          guard let accessToken = config["accessToken"] as? String else {
            promise.reject("MISSING_ACCESS_TOKEN", "Access token is required")
            return
          }

          spotifyAppRemote.connect(accessToken: accessToken).done { connected in
            promise.resolve([
              "connected": connected
            ])
          }.catch { error in
            log.error(error)
            promise.reject(error)
          }
        }

        AsyncFunction("disconnectAppRemoteAsync") { (promise: Promise) in
          log.info("disconnect app remote async called")

          spotifyAppRemote.disconnect().done { success in
            promise.resolve([
              "disconnected": success
            ])
          }.catch { error in
            log.error(error)
            promise.reject(error)
          }
        }


         AsyncFunction("playAsync") { (promise: Promise) in
           log.info("play async called")

           guard let appRemote = spotifyAppRemote.appRemote else {
             log.error("Failed to play: Spotify App Remote is not connected")
             promise.reject("NOT_CONNECTED", "Spotify App Remote is not connected")
             return
           }

           appRemote.playerAPI?.resume({ (_, error) in
             if let error = error {
               log.error(error)
               promise.reject(error)
             } else {
               promise.resolve([
                 "success": true
               ])
             }
           })
         }

         AsyncFunction("pauseAsync") { (promise: Promise) in
           log.info("pause async called")

           guard let appRemote = spotifyAppRemote.appRemote else {
             promise.reject("NOT_CONNECTED", "Spotify App Remote is not connected")
             return
           }
           log.info(appRemote.playerAPI)

           appRemote.playerAPI?.pause({ (_, error) in
             if let error = error {
               log.error(error)
               promise.reject(error)
             } else {
               promise.resolve([
                 "success": true
               ])
             }
           })
         }

         AsyncFunction("getPlayerStateAsync") { (promise: Promise) in
           log.info("get player state async called")

           guard let appRemote = spotifyAppRemote.appRemote else {
             promise.reject("NOT_CONNECTED", "Spotify App Remote is not connected")
             return
           }

           appRemote.playerAPI?.getPlayerState({ (playerState, error) in
             if let error = error {
               log.error(error)
               promise.reject(error)
               return
             }

             guard let playerState = playerState as? SPTAppRemotePlayerState else {
               promise.reject("PLAYER_STATE_ERROR", "Failed to get player state")
               return
             }

             let trackInfo = playerState.track
             let artistName = trackInfo.artist.name

             let playerStateDict: [String: Any] = [
               "playerState": [
                 "isPaused": playerState.isPaused,
                 "track": [
                   "name": trackInfo.name,
                   "uri": trackInfo.uri,
                   "artist": [
                     "name": artistName
                   ]
                 ]
               ]
             ]

             promise.resolve(playerStateDict)
           })
         }

         AsyncFunction("subscribeToPlayerStateAsync") { (promise: Promise) in
           log.info("subscribe to player state async called")

           guard let appRemote = spotifyAppRemote.appRemote else {
             promise.reject("NOT_CONNECTED", "Spotify App Remote is not connected")
             return
           }

           spotifyAppRemote.subscribeToPlayerState().done { success in
             promise.resolve([
               "success": success
             ])
           }.catch { error in
             log.error(error)
             promise.reject(error)
           }
         }

         AsyncFunction("unsubscribeFromPlayerStateAsync") { (promise: Promise) in
           log.info("unsubscribe from player state async called")

           guard let appRemote = spotifyAppRemote.appRemote else {
             promise.reject("NOT_CONNECTED", "Spotify App Remote is not connected")
             return
           }

           spotifyAppRemote.unsubscribeFromPlayerState().done { success in
             promise.resolve([
               "success": success
             ])
           }.catch { error in
             log.error(error)
             promise.reject(error)
           }
         }

         AsyncFunction("skipToNextAsync") { (promise: Promise) in
           log.info("skip to next async called")

           guard let appRemote = spotifyAppRemote.appRemote else {
             promise.reject("NOT_CONNECTED", "Spotify App Remote is not connected")
             return
           }

           spotifyAppRemote.skipToNext().done { success in
             promise.resolve([
               "success": success
             ])
           }.catch { error in
             log.error(error)
             promise.reject(error)
           }
         }

         AsyncFunction("skipToPreviousAsync") { (promise: Promise) in
           log.info("skip to previous async called")

           guard let appRemote = spotifyAppRemote.appRemote else {
             promise.reject("NOT_CONNECTED", "Spotify App Remote is not connected")
             return
           }

           spotifyAppRemote.skipToPrevious().done { success in
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
