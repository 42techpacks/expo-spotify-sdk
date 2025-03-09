import { AppRemote } from "expo-spotify-sdk";
import { useEffect, useState } from "react";

import { PlayerState } from "../../../src/ExpoSpotifySDK.types";

export function useSpotifyPlayerState() {
  const [playerState, setPlayerState] = useState<PlayerState | null>(null);
  const [isSubscribed, setIsSubscribed] = useState(false);

  useEffect(() => {
    // Subscribe to player state changes when the component mounts
    const subscribeToPlayerState = async () => {
      try {
        if (AppRemote.isAppRemoteConnected()) {
          const result = await AppRemote.subscribeToPlayerStateAsync();
          setIsSubscribed(result.success);

          // Get initial player state
          const initialState = await AppRemote.getPlayerStateAsync();
          if (initialState.playerState) {
            setPlayerState(initialState.playerState);
          }
        }
      } catch (error) {
        console.error("Failed to subscribe to player state:", error);
      }
    };

    // Set up event listener for player state changes
    const playerStateChangedSubscription =
      AppRemote.addPlayerStateChangedListener((event) => {
        setPlayerState(event.playerState);
      });

    // Set up event listener for app remote connection
    const connectedSubscription = AppRemote.addAppRemoteConnectedListener(
      async (event) => {
        if (event.connected) {
          await subscribeToPlayerState();
        } else {
          setPlayerState(null);
          setIsSubscribed(false);
        }
      },
    );

    // Set up event listener for app remote disconnection
    const disconnectedSubscription = AppRemote.addAppRemoteDisconnectedListener(
      () => {
        setPlayerState(null);
        setIsSubscribed(false);
      },
    );

    // Initial subscription if already connected
    if (AppRemote.isAppRemoteConnected()) {
      subscribeToPlayerState();
    }

    // Clean up subscriptions when the component unmounts
    return () => {
      playerStateChangedSubscription.remove();
      connectedSubscription.remove();
      disconnectedSubscription.remove();

      // Unsubscribe from player state if still subscribed
      if (isSubscribed && AppRemote.isAppRemoteConnected()) {
        AppRemote.unsubscribeFromPlayerStateAsync().catch(console.error);
      }
    };
  }, []);

  // Toggle play/pause based on current state
  const togglePlayPause = async () => {
    try {
      if (!AppRemote.isAppRemoteConnected()) {
        return { success: false };
      }

      if (playerState?.isPaused) {
        return await AppRemote.playAsync();
      } else {
        return await AppRemote.pauseAsync();
      }
    } catch (error) {
      console.error("Failed to toggle play/pause:", error);
      return { success: false };
    }
  };

  return {
    playerState,
    isPlaying: playerState ? !playerState.isPaused : false,
    togglePlayPause,
  };
}
