import React from "react";
import {
  ActivityIndicator,
  StyleSheet,
  TouchableOpacity,
  View,
} from "react-native";

import { useSpotifyAppRemote } from "../hooks/useSpotifyAppRemote";
import { useSpotifyPlayerState } from "../hooks/useSpotifyPlayerState";

interface PlayPauseButtonProps {
  size?: number;
  color?: string;
  style?: any;
}

export function PlayPauseButton({
  size = 50,
  color = "#1DB954",
  style,
}: PlayPauseButtonProps) {
  const { isConnected } = useSpotifyAppRemote();
  const { playerState, isPlaying, togglePlayPause } = useSpotifyPlayerState();
  const [isLoading, setIsLoading] = React.useState(false);

  const handlePress = async () => {
    if (!isConnected) {
      // Don't even try to toggle if not connected
      return;
    }

    setIsLoading(true);
    try {
      const result = await togglePlayPause();
      // If the toggle operation failed, we should still reset the loading state
      if (!result.success) {
        console.warn("Toggle playback operation failed");
      }
    } catch (error) {
      console.error("Error toggling playback:", error);
    } finally {
      // Ensure loading state is always reset
      setIsLoading(false);
    }
  };

  // Calculate styles based on props
  const buttonSize = { width: size, height: size };
  const iconSize = size * 0.5;

  // Play icon is a triangle pointing right
  const renderPlayIcon = () => (
    <View
      style={[
        styles.playIcon,
        {
          borderLeftWidth: iconSize,
          borderTopWidth: iconSize / 2,
          borderBottomWidth: iconSize / 2,
        },
      ]}
    />
  );

  // Pause icon is two parallel rectangles
  const renderPauseIcon = () => (
    <View style={styles.pauseContainer}>
      <View
        style={[styles.pauseBar, { width: iconSize / 3, height: iconSize }]}
      />
      <View
        style={[styles.pauseBar, { width: iconSize / 3, height: iconSize }]}
      />
    </View>
  );

  return (
    <TouchableOpacity
      style={[
        styles.button,
        buttonSize,
        { backgroundColor: color },
        style,
        isLoading && styles.loading,
        !isConnected && styles.disabled,
      ]}
      onPress={handlePress}
      disabled={isLoading || !isConnected}
    >
      {isLoading ? (
        <ActivityIndicator color="#FFFFFF" size="small" />
      ) : isPlaying ? (
        renderPauseIcon()
      ) : (
        renderPlayIcon()
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    borderRadius: 50,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#fff",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 3,
  },
  loading: {
    opacity: 0.7,
  },
  disabled: {
    opacity: 0.5,
  },
  playIcon: {
    width: 0,
    height: 0,
    backgroundColor: "transparent",
    borderStyle: "solid",
    borderLeftColor: "#FFFFFF",
    borderTopColor: "transparent",
    borderBottomColor: "transparent",
    marginLeft: 5, // Offset to center the triangle
  },
  pauseContainer: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    width: "100%",
    height: "100%",
    gap: 5,
  },
  pauseBar: {
    backgroundColor: "#FFFFFF",
    borderRadius: 2,
  },
});
