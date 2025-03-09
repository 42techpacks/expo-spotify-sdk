import { AppRemote } from "expo-spotify-sdk";
import { useEffect, useState } from "react";

export function useSpotifyAppRemote() {
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    // Check initial connection state
    setIsConnected(AppRemote.isAppRemoteConnected());
  }, []);

  return {
    isConnected,
    playAsync: AppRemote.playAsync,
    pauseAsync: AppRemote.pauseAsync,
    authorizeAndPlayURI: AppRemote.authorizeAndPlayURIAsync,
    connectAppRemote: AppRemote.connectAppRemoteAsync,
    disconnectAppRemote: AppRemote.disconnectAppRemoteAsync,
  };
}
