import ExpoModulesCore
import SpotifyiOS
import PromiseKit

enum SessionManagerError: Error {
    case notInitialized
    case invalidConfiguration
    case appRemoteNotConnected
}

final class ExpoSpotifySessionManager: NSObject, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    weak var module: ExpoSpotifySDKModule?
    var authPromiseSeal: Resolver<SPTSession>?
    var appRemotePromiseSeal: Resolver<Void>?
    var playerStatePromiseSeal: Resolver<[String: Any]>?
    var playbackPromiseSeal: Resolver<Void>?
    var albumArtPromiseSeal: Resolver<String>?

    // App Remote properties
    private var appRemote: SPTAppRemote?

    static let shared = ExpoSpotifySessionManager()

    private var expoSpotifyConfiguration: ExpoSpotifyConfiguration? {
        guard let expoSpotifySdkDict = Bundle.main.object(forInfoDictionaryKey: "ExpoSpotifySDK") as? [String: String],
              let clientID = expoSpotifySdkDict["clientID"],
              let host = expoSpotifySdkDict["host"],
              let scheme = expoSpotifySdkDict["scheme"] else
        {
            return nil
        }
      log.info(clientID, host, scheme)

        return ExpoSpotifyConfiguration(clientID: clientID, host: host, scheme: scheme)
    }

    lazy var configuration: SPTConfiguration? = {
        guard let clientID = expoSpotifyConfiguration?.clientID,
              let redirectURL = expoSpotifyConfiguration?.redirectURL else {
            NSLog("Invalid Spotify configuration")
            return nil
        }

        return SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
    }()

    lazy var sessionManager: SPTSessionManager? = {
        guard let configuration = configuration else {
            return nil
        }

        return SPTSessionManager(configuration: configuration, delegate: self)
    }()

    func authenticate(scopes: [String], tokenSwapURL: String?, tokenRefreshURL: String?) -> PromiseKit.Promise<SPTSession> {
        return Promise { seal in
            guard let clientID = self.expoSpotifyConfiguration?.clientID,
                  let redirectURL = self.expoSpotifyConfiguration?.redirectURL else {
                NSLog("Invalid Spotify configuration")
                seal.reject(SessionManagerError.invalidConfiguration)
                return
            }

            let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)

            if (tokenSwapURL != nil) {
                configuration.tokenSwapURL = URL(string: tokenSwapURL ?? "")
            }

            if (tokenRefreshURL != nil) {
                configuration.tokenRefreshURL = URL(string: tokenRefreshURL ?? "")
            }

            self.authPromiseSeal = seal
            self.configuration = configuration
            self.sessionManager = SPTSessionManager(configuration: configuration, delegate: self)

            DispatchQueue.main.sync {
                sessionManager?.initiateSession(with: SPTScopeSerializer.deserializeScopes(scopes), options: .default, campaign: nil)
            }
        }
    }

    func spotifyAppInstalled() -> Bool {
        guard let sessionManager = sessionManager else {
            NSLog("SPTSessionManager not initialized")
            return false
        }

        var isInstalled = false

        DispatchQueue.main.sync {
            isInstalled = sessionManager.isSpotifyAppInstalled
        }

        return isInstalled
    }

    // MARK: - App Remote Methods

    func connectToAppRemote(accessToken: String) -> Promise<Void> {
        return Promise { seal in
            guard let configuration = configuration else {
                seal.reject(SessionManagerError.invalidConfiguration)
                return
            }

            let connectionParams = SPTAppRemoteConnectionParams(accessToken: accessToken)
            appRemote = SPTAppRemote(configuration: configuration, connectionParameters: connectionParams, logLevel: .debug)
            appRemote?.delegate = self

            self.appRemotePromiseSeal = seal

            DispatchQueue.main.async {
                self.appRemote?.connect()
            }
        }
    }

    func disconnectFromAppRemote() {
        DispatchQueue.main.async {
            self.appRemote?.disconnect()
            self.appRemote = nil
        }
    }

    // MARK: - Playback Control Methods

    func play(uri: String) -> Promise<Void> {
        return Promise { seal in
            guard let appRemote = appRemote, appRemote.isConnected else {
                seal.reject(SessionManagerError.appRemoteNotConnected)
                return
            }

            self.playbackPromiseSeal = seal

            appRemote.playerAPI?.play(uri, callback: { [weak self] result, error in
                if let error = error {
                    self?.playbackPromiseSeal?.reject(error)
                } else {
                    self?.playbackPromiseSeal?.fulfill(())
                }
            })
        }
    }

    func resume() -> Promise<Void> {
        return Promise { seal in
            guard let appRemote = appRemote, appRemote.isConnected else {
                seal.reject(SessionManagerError.appRemoteNotConnected)
                return
            }

            self.playbackPromiseSeal = seal

            appRemote.playerAPI?.resume({ [weak self] result, error in
                if let error = error {
                    self?.playbackPromiseSeal?.reject(error)
                } else {
                    self?.playbackPromiseSeal?.fulfill(())
                }
            })
        }
    }

    func pause() -> Promise<Void> {
        return Promise { seal in
            guard let appRemote = appRemote, appRemote.isConnected else {
                seal.reject(SessionManagerError.appRemoteNotConnected)
                return
            }

            self.playbackPromiseSeal = seal

            appRemote.playerAPI?.pause({ [weak self] result, error in
                if let error = error {
                    self?.playbackPromiseSeal?.reject(error)
                } else {
                    self?.playbackPromiseSeal?.fulfill(())
                }
            })
        }
    }

    func skipToNext() -> Promise<Void> {
        return Promise { seal in
            guard let appRemote = appRemote, appRemote.isConnected else {
                seal.reject(SessionManagerError.appRemoteNotConnected)
                return
            }

            self.playbackPromiseSeal = seal

            appRemote.playerAPI?.skipToNext({ [weak self] result, error in
                if let error = error {
                    self?.playbackPromiseSeal?.reject(error)
                } else {
                    self?.playbackPromiseSeal?.fulfill(())
                }
            })
        }
    }

    func skipToPrevious() -> Promise<Void> {
        return Promise { seal in
            guard let appRemote = appRemote, appRemote.isConnected else {
                seal.reject(SessionManagerError.appRemoteNotConnected)
                return
            }

            self.playbackPromiseSeal = seal

            appRemote.playerAPI?.skipToPrevious({ [weak self] result, error in
                if let error = error {
                    self?.playbackPromiseSeal?.reject(error)
                } else {
                    self?.playbackPromiseSeal?.fulfill(())
                }
            })
        }
    }

    // MARK: - Player State Methods

    func getPlayerState() -> Promise<[String: Any]> {
        return Promise { seal in
            guard let appRemote = appRemote, appRemote.isConnected else {
                seal.reject(SessionManagerError.appRemoteNotConnected)
                return
            }

            self.playerStatePromiseSeal = seal

            appRemote.playerAPI?.getPlayerState({ [weak self] result, error in
                if let error = error {
                    self?.playerStatePromiseSeal?.reject(error)
                    return
                }

                guard let playerState = result as? SPTAppRemotePlayerState else {
                    self?.playerStatePromiseSeal?.reject(NSError(domain: "com.spotify.appremote", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid player state"]))
                    return
                }

                let state = self?.serializePlayerState(playerState)
                self?.playerStatePromiseSeal?.fulfill(state ?? [:])
            })
        }
    }

    func subscribeToPlayerState() -> Promise<Void> {
        return Promise { seal in
            guard let appRemote = appRemote, appRemote.isConnected else {
                seal.reject(SessionManagerError.appRemoteNotConnected)
                return
            }

            appRemote.playerAPI?.delegate = self

            appRemote.playerAPI?.subscribeToPlayerState({ result, error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            })
        }
    }

    func getAlbumArt(size: CGSize) -> Promise<String> {
        return Promise { seal in
            guard let appRemote = appRemote, appRemote.isConnected else {
                seal.reject(SessionManagerError.appRemoteNotConnected)
                return
            }

            self.albumArtPromiseSeal = seal

            appRemote.playerAPI?.getPlayerState({ [weak self] result, error in
                if let error = error {
                    self?.albumArtPromiseSeal?.reject(error)
                    return
                }

                guard let playerState = result as? SPTAppRemotePlayerState else {
                    self?.albumArtPromiseSeal?.reject(NSError(domain: "com.spotify.appremote", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid player state"]))
                    return
                }

                appRemote.imageAPI?.fetchImage(forItem: playerState.track, withSize: size, callback: { [weak self] image, error in
                    if let error = error {
                        self?.albumArtPromiseSeal?.reject(error)
                        return
                    }

                    guard let image = image as? UIImage else {
                        self?.albumArtPromiseSeal?.reject(NSError(domain: "com.spotify.appremote", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"]))
                        return
                    }

                    // Convert UIImage to base64 string
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        self?.albumArtPromiseSeal?.reject(NSError(domain: "com.spotify.appremote", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]))
                        return
                    }

                    let base64String = imageData.base64EncodedString()
                    self?.albumArtPromiseSeal?.fulfill(base64String)
                })
            })
        }
    }

    // MARK: - Helper Methods

    private func serializePlayerState(_ playerState: SPTAppRemotePlayerState) -> [String: Any] {
        let track = playerState.track

        var trackData: [String: Any] = [
            "name": track.name,
            "uri": track.URI,
            "duration": track.duration,
            "isPaused": playerState.isPaused,
            "playbackPosition": playerState.playbackPosition,
            "playbackSpeed": playerState.playbackSpeed
        ]

        if let artist = track.artist {
            trackData["artist"] = [
                "name": artist.name,
                "uri": artist.URI
            ]
        }

        if let album = track.album {
            trackData["album"] = [
                "name": album.name,
                "uri": album.URI
            ]
        }

        return trackData
    }

    // MARK: - SPTAppRemoteDelegate Methods

    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        appRemotePromiseSeal?.fulfill(())
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        if let error = error {
            appRemotePromiseSeal?.reject(error)
        } else {
            appRemotePromiseSeal?.reject(NSError(domain: "com.spotify.appremote", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to connect to App Remote"]))
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        // Handle disconnection
    }

    // MARK: - SPTAppRemotePlayerStateDelegate Methods

    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        let state = serializePlayerState(playerState)
        module?.sendEvent("onPlayerStateChanged", state)
    }
}
