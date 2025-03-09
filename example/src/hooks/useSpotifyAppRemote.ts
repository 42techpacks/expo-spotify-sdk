import { isSpotifyAppInstalled, AppRemote } from "expo-spotify-sdk";
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
        setConnectionError(event.error || null);
      },
    );

    // Check initial connection state
    setIsConnected(AppRemote.isAppRemoteConnected());

    // Clean up subscriptions
    return () => {
      connectedSubscription.remove();
      connectionFailureSubscription.remove();
      disconnectedSubscription.remove();
    };
  }, []);

  return {
    isSpotifyAppInstalled,
    isConnected,
    connectionError,
    connectAppRemote: AppRemote.connectAppRemoteAsync,
    disconnectAppRemote: AppRemote.disconnectAppRemoteAsync,
    authorizeAndPlayURI: AppRemote.authorizeAndPlayURIAsync,
  };
}
