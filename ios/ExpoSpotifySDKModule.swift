import ExpoModulesCore
import SpotifyiOS

public class ExpoSpotifySDKModule: Module {

    public func definition() -> ModuleDefinition {

        let spotifySession = ExpoSpotifySessionManager.shared

        Name("ExpoSpotifySDK")

        Function("isAvailable") {
            return spotifySession.spotifyAppInstalled()
        }

        AsyncFunction("authenticateAsync") { (config: [String: Any], promise: Promise) in
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
}
