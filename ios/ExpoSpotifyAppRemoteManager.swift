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
}

final class ExpoSpotifyAppRemoteManager: NSObject {
    weak var module: ExpoSpotifySDKModule?
    var connectionPromiseSeal: Resolver<Bool>?

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
            NSLog("accessToken: \(self.accessToken)")

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
}

// MARK: - SPTAppRemoteDelegate

extension ExpoSpotifyAppRemoteManager: SPTAppRemoteDelegate {
    public func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        NSLog("🔥 App Remote connection established")
        isConnected = true
        connectionPromiseSeal?.fulfill(true)

        // Notify JS side about connection status change
        // module?.sendEvent("onAppRemoteConnected", [
        //     "connected": true
        // ])
    }

    public func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        NSLog("🔥 App Remote connection failed: \(error?.localizedDescription ?? "unknown error")")
        isConnected = false

        if let error = error {
            connectionPromiseSeal?.reject(error)
        } else {
            connectionPromiseSeal?.reject(AppRemoteError.connectionFailed)
        }

        // Notify JS side about connection failure
        // module?.sendEvent("onAppRemoteConnectionFailure", [
        //     "error": error?.localizedDescription ?? "Connection failed"
        // ])
    }

    public func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        NSLog("🔥 App Remote disconnected: \(error?.localizedDescription ?? "no error")")
        isConnected = false

        // Notify JS side about disconnection
        // module?.sendEvent("onAppRemoteDisconnected", [
        //     "error": error?.localizedDescription
        // ])
    }
}
