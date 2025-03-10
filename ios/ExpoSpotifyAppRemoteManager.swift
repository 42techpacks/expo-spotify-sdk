import ExpoModulesCore
import SpotifyiOS
import PromiseKit
import Foundation

enum AppRemoteError: Error {
    case notInitialized
    case invalidConfiguration
    case connectionFailed
    case spotifyAppNotInstalled
    case accessTokenMissing
    case playerStateSubscriptionFailed
}

final class ExpoSpotifyAppRemoteManager: NSObject {
    weak var module: ExpoSpotifySDKModule?
    var connectionPromiseSeal: Resolver<Bool>?
    private var isSubscribedToPlayerState = false

    static let shared = ExpoSpotifyAppRemoteManager()

    private var expoSpotifyConfiguration: ExpoSpotifyConfiguration? {
        guard let expoSpotifySdkDict = Bundle.main.object(forInfoDictionaryKey: "ExpoSpotifySDK") as? [String: String],
              let clientID = expoSpotifySdkDict["clientID"],
              let host = expoSpotifySdkDict["host"],
              let scheme = expoSpotifySdkDict["scheme"] else
        {
            return nil
        }

        return ExpoSpotifyConfiguration(clientID: clientID, host: host, scheme: scheme)
    }

    var accessToken: String? {
        didSet {
            appRemote?.connectionParameters.accessToken = accessToken
        }
    }

    //TODO: This should be private(var)
    var isConnected = false

    lazy var appRemote: SPTAppRemote? = {
        guard let clientID = expoSpotifyConfiguration?.clientID,
              let redirectURL = expoSpotifyConfiguration?.redirectURL else {
            NSLog("Invalid Spotify configuration")
            return nil
        }

        let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()

    func spotifyAppInstalled() -> Bool {
        return ExpoSpotifySessionManager.shared.spotifyAppInstalled()
    }

    func authorizeAndPlayURI(uri: String) -> PromiseKit.Promise<Bool> {
        return Promise { seal in
            guard let appRemote = self.appRemote else {
                NSLog("SPTAppRemote not initialized")
                seal.reject(AppRemoteError.notInitialized)
                return
            }

            guard spotifyAppInstalled() else {
                seal.reject(AppRemoteError.spotifyAppNotInstalled)
                return
            }

            DispatchQueue.main.async {
                appRemote.authorizeAndPlayURI(uri) { success in
                    seal.fulfill(success)
                }
            }
        }
    }

    func connect(accessToken: String?) -> PromiseKit.Promise<Bool> {
        return Promise { seal in
            guard let appRemote = self.appRemote else {
                NSLog("SPTAppRemote not initialized")
                seal.reject(AppRemoteError.notInitialized)
                return
            }

            guard spotifyAppInstalled() else {
                seal.reject(AppRemoteError.spotifyAppNotInstalled)
                return
            }

            self.accessToken = accessToken

            if accessToken == nil {
                seal.reject(AppRemoteError.accessTokenMissing)
                return
            }

            connectionPromiseSeal = seal

            DispatchQueue.main.async {
                if appRemote.isConnected {
                    self.isConnected = true
                    seal.fulfill(true)
                } else {
                    appRemote.connect()
                }
            }
        }
    }

    func disconnect() -> PromiseKit.Promise<Bool> {
        return Promise { seal in
            guard let appRemote = self.appRemote else {
                seal.fulfill(true) // Already disconnected if appRemote is nil
                return
            }

            DispatchQueue.main.async {
                if appRemote.isConnected {
                    appRemote.disconnect()
                    self.isConnected = false
                }
                seal.fulfill(true)
            }
        }
    }

    func subscribeToPlayerState() -> PromiseKit.Promise<Bool> {
        return Promise { seal in
            guard let appRemote = self.appRemote, appRemote.isConnected else {
                seal.reject(AppRemoteError.notInitialized)
                return
            }

            appRemote.playerAPI?.delegate = self

            appRemote.playerAPI?.subscribe { (_, error) in
                if let error = error {
                    NSLog("Failed to subscribe to player state: \(error.localizedDescription)")
                    seal.reject(AppRemoteError.playerStateSubscriptionFailed)
                    return
                }

                self.isSubscribedToPlayerState = true
                seal.fulfill(true)
            }
        }
    }

    func unsubscribeFromPlayerState() -> PromiseKit.Promise<Bool> {
        return Promise { seal in
            guard let appRemote = self.appRemote, appRemote.isConnected else {
                seal.fulfill(true) // Already disconnected if appRemote is nil or not connected
                return
            }

            if !isSubscribedToPlayerState {
                seal.fulfill(true) // Already unsubscribed
                return
            }

            appRemote.playerAPI?.unsubscribe { (_, error) in
                if let error = error {
                    NSLog("Failed to unsubscribe from player state: \(error.localizedDescription)")
                    seal.reject(error)
                    return
                }

                self.isSubscribedToPlayerState = false
                seal.fulfill(true)
            }
        }
    }

    func skipToNext() -> PromiseKit.Promise<Bool> {
        return Promise { seal in
            guard let appRemote = self.appRemote, appRemote.isConnected else {
                seal.reject(AppRemoteError.notInitialized)
                return
            }

            appRemote.playerAPI?.skip(toNext: { (_, error) in
                if let error = error {
                    NSLog("Failed to skip to next track: \(error.localizedDescription)")
                    seal.reject(error)
                    return
                }

                seal.fulfill(true)
            })
        }
    }

    func skipToPrevious() -> PromiseKit.Promise<Bool> {
        return Promise { seal in
            guard let appRemote = self.appRemote, appRemote.isConnected else {
                seal.reject(AppRemoteError.notInitialized)
                return
            }

            appRemote.playerAPI?.skip(toPrevious: { (_, error) in
                if let error = error {
                    NSLog("Failed to skip to previous track: \(error.localizedDescription)")
                    seal.reject(error)
                    return
                }

                seal.fulfill(true)
            })
        }
    }
}

// MARK: - SPTAppRemoteDelegate

extension ExpoSpotifyAppRemoteManager: SPTAppRemoteDelegate {
    public func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        NSLog("🔥 App Remote connection established")
        isConnected = true
        connectionPromiseSeal?.fulfill(true)
        if module == nil {
            NSLog("😖 Module is nil during connection establishment")
        }

        // Notify JS side about connection status change
        module?.sendEvent("onAppRemoteConnected", [
            "connected": true
        ])
    }

    public func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        NSLog("🔥 App Remote connection failed: \(error?.localizedDescription ?? "unknown error")")
        isConnected = false

        if let error = error {
            connectionPromiseSeal?.reject(error)
        } else {
            connectionPromiseSeal?.reject(AppRemoteError.connectionFailed)
        }

        if module == nil {
            NSLog("😖 Module is nil during connection failure")
        }

        // Notify JS side about connection failure
        module?.sendEvent("onAppRemoteConnectionFailure", [
            "error": error?.localizedDescription ?? "Connection failed"
        ])
    }

    public func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        NSLog("🔥 App Remote disconnected: \(error?.localizedDescription ?? "no error")")
        isConnected = false
        isSubscribedToPlayerState = false

        // Notify JS side about disconnection
        module?.sendEvent("onAppRemoteDisconnected", [
            "error": error?.localizedDescription
        ])
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension ExpoSpotifyAppRemoteManager: SPTAppRemotePlayerStateDelegate {
    public func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        NSLog("🎵 Player state changed")

        let trackInfo = playerState.track
        let artistName = trackInfo.artist.name

        // Create the player state event data
        var playerStateData: [String: Any] = [
            "isPaused": playerState.isPaused,
            "track": [
                "name": trackInfo.name,
                "uri": trackInfo.uri,
                "artist": [
                    "name": artistName
                ]
            ]
        ]

        // Fetch the track image
        appRemote?.imageAPI?.fetchImage(forItem: trackInfo, with: CGSize(width: 640, height: 640), callback: { (image, error) in
            if let error = error {
                NSLog("Failed to fetch track image: \(error.localizedDescription)")
                // Send the player state event without the image
                self.module?.sendEvent("onPlayerStateChanged", [
                    "playerState": playerStateData
                ])
                return
            }

            if let image = image as? UIImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                let base64String = imageData.base64EncodedString()
                let imageUri = "data:image/jpeg;base64,\(base64String)"

                // Update the player state with the image URI
                if var trackData = playerStateData["track"] as? [String: Any] {
                    trackData["imageUri"] = imageUri
                    playerStateData["track"] = trackData
                }
            }

            if self.module == nil {
                NSLog("😖 Module is nil during player state change")
            }

            // Send the player state event with the image
            self.module?.sendEvent("onPlayerStateChanged", [
                "playerState": playerStateData
            ])
        })
    }
}
