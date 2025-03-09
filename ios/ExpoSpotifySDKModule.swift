import ExpoModulesCore
import SpotifyiOS

public class ExpoSpotifySDKModule: Module {

    public func definition() -> ModuleDefinition {

        let spotifySession = ExpoSpotifySessionManager.shared
        let spotifyAppRemote = ExpoSpotifyAppRemoteManager.shared

        // Set the module reference in our managers
//      spotifySession as! ExpoSpotifySessionManager.module = self
//      spotifyAppRemote as! AnyDefinition.module = self

        Name("ExpoSpotifySDK")

        // Events for App Remote connection status
        Events("onAppRemoteConnected", "onAppRemoteConnectionFailure", "onAppRemoteDisconnected", "onAccessTokenReceived")

        OnCreate {
            NSLog("ExpoSpotifySDKModule OnCreate")
            // Register for URL events from Expo
            // let eventEmitter = self.appContext?.eventEmitter
            // eventEmitter?.addListener(self, eventName: "expo-spotify-sdk-handle-url") { (body: [AnyHashable: Any]?) in
            //     guard let urlString = body?["url"] as? String,
            //           let url = URL(string: urlString) else {
            //         return
            //     }

            //     self.handleURL(url: url)
            // }
        }

        Function("handleURL") { (urlString: String) in
            guard let url = URL(string: urlString) else {
                return false
            }

            return self.handleURL(url: url)
        }

        Function("isAvailable") {
          return spotifySession.spotifyAppInstalled()
        }

        //TODO: This is redundant
        Function("isSpotifyAppInstalled") {
          return spotifyAppRemote.spotifyAppInstalled()
        }

        Function("isAppRemoteConnected") {
          return spotifyAppRemote.isConnected
        }

        AsyncFunction("authenticateAsync") { (config: [String: Any], promise: Promise) in
          log.info("authenticate async called")
          guard let scopes = config["scopes"] as? [String] else {
            promise.reject("INVALID_CONFIG", "Invalid SpotifyConfig object")
            return
          }

          let tokenSwapURL = config["tokenSwapURL"] as? String
          let tokenRefreshURL = config["tokenRefreshURL"] as? String

          spotifySession.authenticate(scopes: scopes, tokenSwapURL: tokenSwapURL, tokenRefreshURL: tokenRefreshURL).done { session in
            promise.resolve([
              "accessToken": session.accessToken,
              "refreshToken": session.refreshToken,
              "expirationDate": Int(session.expirationDate.timeIntervalSince1970 * 1000),
              "scopes": SPTScopeSerializer.serializeScopes(session.scope)
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

        AsyncFunction("authorizeAndPlayURIAsync") { (config: [String: Any], promise: Promise) in
          log.info("authorize and play URI async called")
          guard let uri = config["uri"] as? String else {
            promise.reject("MISSING_URI", "URI is required")
            return
          }

          let asRadio = config["asRadio"] as? Bool ?? false

          spotifyAppRemote.authorizeAndPlayURI(uri: uri, asRadio: asRadio).done { success in
            promise.resolve([
              "success": success
            ])
          }.catch { error in
            log.error(error)
            promise.reject(error)
          }
        }

        // Add App Remote functionality
        AsyncFunction("connectToAppRemote") { (accessToken: String, promise: Promise) in
            spotifySession.connectToAppRemote(accessToken: accessToken).done {
                promise.resolve(true)
            }.catch { error in
                promise.reject("APP_REMOTE_CONNECTION_ERROR", "Failed to connect to Spotify App Remote", error)
            }
        }

        AsyncFunction("disconnectFromAppRemote") { (promise: Promise) in
            spotifySession.disconnectFromAppRemote()
            promise.resolve(true)
        }

        // Playback control functions
        AsyncFunction("play") { (uri: String, promise: Promise) in
            spotifySession.play(uri: uri).done {
                promise.resolve(true)
            }.catch { error in
                promise.reject("PLAYBACK_ERROR", "Failed to play track", error)
            }
        }

        AsyncFunction("resume") { (promise: Promise) in
            spotifySession.resume().done {
                promise.resolve(true)
            }.catch { error in
                promise.reject("PLAYBACK_ERROR", "Failed to resume playback", error)
            }
        }

        AsyncFunction("pause") { (promise: Promise) in
            spotifySession.pause().done {
                promise.resolve(true)
            }.catch { error in
                promise.reject("PLAYBACK_ERROR", "Failed to pause playback", error)
            }
        }

        AsyncFunction("skipToNext") { (promise: Promise) in
            spotifySession.skipToNext().done {
                promise.resolve(true)
            }.catch { error in
                promise.reject("PLAYBACK_ERROR", "Failed to skip to next track", error)
            }
        }

        AsyncFunction("skipToPrevious") { (promise: Promise) in
            spotifySession.skipToPrevious().done {
                promise.resolve(true)
            }.catch { error in
                promise.reject("PLAYBACK_ERROR", "Failed to skip to previous track", error)
            }
        }

        // Player state functions
        AsyncFunction("getPlayerState") { (promise: Promise) in
            spotifySession.getPlayerState().done { playerState in
                promise.resolve(playerState)
            }.catch { error in
                promise.reject("PLAYER_STATE_ERROR", "Failed to get player state", error)
            }
        }

        // Image API for album art
        AsyncFunction("getAlbumArt") { (imageSize: [String: Any], promise: Promise) in
            guard let width = imageSize["width"] as? CGFloat,
                  let height = imageSize["height"] as? CGFloat else {
                promise.reject("INVALID_IMAGE_SIZE", "Invalid image size")
                return
            }

            spotifySession.getAlbumArt(size: CGSize(width: width, height: height)).done { imageData in
                promise.resolve(imageData)
            }.catch { error in
                promise.reject("ALBUM_ART_ERROR", "Failed to get album art", error)
            }
        }

        // Subscribe to player state changes
        AsyncFunction("subscribeToPlayerState") { (promise: Promise) in
            spotifySession.subscribeToPlayerState().done {
                promise.resolve(true)
            }.catch { error in
                promise.reject("SUBSCRIPTION_ERROR", "Failed to subscribe to player state", error)
            }
        }

        // Event emitter for player state changes
        EventEmitter("onPlayerStateChanged")
    }

    // MARK: - URL Handling

    func handleURL(url: URL) -> Bool {
        let spotifyAppRemote = ExpoSpotifyAppRemoteManager.shared

        guard let appRemote = spotifyAppRemote.appRemote else {
            return false
        }

        let parameters = appRemote.authorizationParameters(from: url)

        if let accessToken = parameters?[SPTAppRemoteAccessTokenKey] {
            // Store the access token in the app remote connection parameters
            spotifyAppRemote.accessToken = accessToken

            // Notify JS side about the received access token
            sendEvent("onAccessTokenReceived", [
                "accessToken": accessToken
            ])

            return true
        } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
            // Handle error
            NSLog("Authorization error: \(errorDescription)")
            return false
        }

        return false
    }
}
