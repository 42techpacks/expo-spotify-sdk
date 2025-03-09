import { isAvailable, AppRemote } from "expo-spotify-sdk";
import { useEffect, useState } from "react";

export function useSpotifyAppRemote() {
  const [isConnected, setIsConnected] = useState(false);
  const [connectionError, setConnectionError] = useState<string | null>(null);

  useEffect(() => {
    // Set up event listeners
    const connectedSubscription = AppRemote.addAppRemoteConnectedListener(
      (event) => {
        setIsConnected(event.connected);
        setConnectionError(null);
      },
    );

    const connectionFailureSubscription =
      AppRemote.addAppRemoteConnectionFailureListener((event) => {
        setIsConnected(false);
        setConnectionError(event.error);
      });

    const disconnectedSubscription = AppRemote.addAppRemoteDisconnectedListener(
      (event) => {
        setIsConnected(false);
        setConnectionError(event.error);
      },
    );

    // Check initial connection state
    setIsConnected(AppRemote.isAppRemoteConnected());

    return () => {
      connectedSubscription.remove();
      connectionFailureSubscription.remove();
      disconnectedSubscription.remove();
    };
  }, []);

  return {
    isSpotifyAppInstalled: isAvailable(),
    isConnected,
    connectionError,
    playAsync: AppRemote.playAsync,
    pauseAsync: AppRemote.pauseAsync,
    skipToNextAsync: AppRemote.skipToNextAsync,
    skipToPreviousAsync: AppRemote.skipToPreviousAsync,
    addToQueueAsync: AppRemote.addToQueueAsync,
    authorizeAndPlayURI: AppRemote.authorizeAndPlayURIAsync,
    connectAppRemote: AppRemote.connectAppRemoteAsync,
    disconnectAppRemote: AppRemote.disconnectAppRemoteAsync,
  };
}
