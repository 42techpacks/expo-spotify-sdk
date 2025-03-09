import ExpoModulesCore
import SpotifyiOS
import PromiseKit

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
//        appRemote.delegate = self
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
}
