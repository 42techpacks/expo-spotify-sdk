import Foundation
import SpotifyiOS

extension ExpoSpotifyAppRemoteManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        NSLog("App Remote connection established")
        isConnected = true
        connectionPromiseSeal?.fulfill(true)

        // Notify JS side about connection status change
        module?.sendEvent("onAppRemoteConnected", [
            "connected": true
        ])
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        NSLog("App Remote connection failed: \(error?.localizedDescription ?? "unknown error")")
        isConnected = false

        if let error = error {
            connectionPromiseSeal?.reject(error)
        } else {
            connectionPromiseSeal?.reject(AppRemoteError.connectionFailed)
        }

        // Notify JS side about connection failure
        module?.sendEvent("onAppRemoteConnectionFailure", [
            "error": error?.localizedDescription ?? "Connection failed"
        ])
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        NSLog("App Remote disconnected: \(error?.localizedDescription ?? "no error")")
        isConnected = false

        // Notify JS side about disconnection
        module?.sendEvent("onAppRemoteDisconnected", [
            "error": error?.localizedDescription
        ])
    }
}
