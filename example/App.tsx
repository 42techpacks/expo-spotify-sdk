import { isAvailable } from "expo-spotify-sdk";
import React, { useState } from "react";
import {
  Alert,
  StyleSheet,
  Text,
  View,
  Button,
  TouchableOpacity,
  Image,
  TextInput,
  ScrollView,
} from "react-native";

import { PlayPauseButton } from "./src/components/PlayPauseButton";
import { useSpotifyAppRemote } from "./src/hooks/useSpotifyAppRemote";
import { useSpotifyAuthentication } from "./src/hooks/useSpotifyAuthentication";
import { useSpotifyPlayerState } from "./src/hooks/useSpotifyPlayerState";

export default function App() {
  const [authToken, setAuthToken] = useState("unknown");
  const [queueUri, setQueueUri] = useState(
    "spotify:track:4iV5W9uYEdYUVa79Axb7Rh",
  ); // Default to a popular track
  const { authenticateAsync } = useSpotifyAuthentication();
  const {
    isConnected,
    authorizeAndPlayURI,
    connectAppRemote,
    disconnectAppRemote,
    skipToNextAsync,
    skipToPreviousAsync,
    addToQueueAsync,
  } = useSpotifyAppRemote();
  const { playerState } = useSpotifyPlayerState();

  async function handleAuthenticatePress() {
    try {
      setAuthToken("unknown");
      const session = await authenticateAsync({
        scopes: [
          "ugc-image-upload",
          "user-read-playback-state",
          "user-modify-playback-state",
          "user-read-currently-playing",
          "app-remote-control",
          "streaming",
          "playlist-read-private",
          "playlist-read-collaborative",
          "playlist-modify-private",
          "playlist-modify-public",
          "user-follow-modify",
          "user-follow-read",
          "user-top-read",
          "user-read-recently-played",
          "user-library-modify",
          "user-library-read",
          "user-read-email",
          "user-read-private",
        ],
      });

      setAuthToken(session.accessToken);
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Error", error.message);
      }
    }
  }

  async function handleAuthorizeAndPlayURIPress() {
    try {
      // Using a sample Spotify URI - you can replace this with any valid URI
      const uri = "spotify:album:1htHMnxonxmyHdKE2uDFMR";

      if (!isConnected) {
        // If not connected, use authorizeAndPlayURI which will handle authorization
        const result = await authorizeAndPlayURI(uri);
        console.log("Authorize and play URI result:", result);

        if (!result.success && !isAvailable()) {
          // Handle case when Spotify app is not installed
          Alert.alert(
            "Spotify Not Installed",
            "Please install the Spotify app from the App Store to continue.",
          );
        }
      } else {
        // If already connected, we could handle playback directly
        // For now, we'll just show a message
        Alert.alert(
          "Already Connected",
          "App Remote is already connected. Direct playback functionality not implemented in this example.",
        );
      }
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Playback Error", error.message);
      }
    }
  }

  async function handleConnectPress() {
    try {
      const result = await connectAppRemote({
        accessToken: authToken,
      });
      console.log("Connect result:", result);

      if (!result.connected) {
        Alert.alert("Error", "Failed to connect to Spotify App Remote");
      }
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Connection Error", error.message);
      }
    }
  }

  async function handleDisconnectPress() {
    try {
      const result = await disconnectAppRemote();
      console.log("Disconnect result:", result);

      if (!result.disconnected) {
        Alert.alert("Error", "Failed to disconnect from Spotify App Remote");
      }
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Disconnection Error", error.message);
      }
    }
  }

  async function handleSkipToNextPress() {
    try {
      if (!isConnected) {
        Alert.alert(
          "Not Connected",
          "Please connect to Spotify App Remote first",
        );
        return;
      }

      const result = await skipToNextAsync();
      console.log("Skip to next result:", result);

      if (!result.success) {
        Alert.alert("Error", "Failed to skip to next track");
      }
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Skip Error", error.message);
      }
    }
  }

  async function handleSkipToPreviousPress() {
    try {
      if (!isConnected) {
        Alert.alert(
          "Not Connected",
          "Please connect to Spotify App Remote first",
        );
        return;
      }

      const result = await skipToPreviousAsync();
      console.log("Skip to previous result:", result);

      if (!result.success) {
        Alert.alert("Error", "Failed to skip to previous track");
      }
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Skip Error", error.message);
      }
    }
  }

  async function handleAddToQueuePress() {
    try {
      if (!isConnected) {
        Alert.alert(
          "Not Connected",
          "Please connect to Spotify App Remote first",
        );
        return;
      }

      const result = await addToQueueAsync({
        uri: queueUri,
      });
      console.log("Add to queue result:", result);

      if (result.success) {
        Alert.alert("Success", "Track added to queue successfully");
      } else {
        Alert.alert("Error", "Failed to add track to queue");
      }
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Queue Error", error.message);
      }
    }
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Spotify SDK Example</Text>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollViewContent}
        showsVerticalScrollIndicator
      >
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Authentication</Text>
          <Button title="Authenticate" onPress={handleAuthenticatePress} />
          <Text>Spotify app is installed: {isAvailable() ? "yes" : "no"}</Text>
          <Text>Auth Token: {authToken.substring(0, 10)}...</Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>App Remote</Text>
          <Button
            title="Authorize and Play URI"
            onPress={handleAuthorizeAndPlayURIPress}
          />
          <Text>Spotify app is installed: {isAvailable() ? "yes" : "no"}</Text>
          <Text>App Remote connected: {isConnected ? "yes" : "no"}</Text>
          <View style={styles.buttonRow}>
            <Button title="Connect" onPress={handleConnectPress} />
            <Button title="Disconnect" onPress={handleDisconnectPress} />
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Queue Management</Text>
          <Text>Add a track to the queue:</Text>
          <TextInput
            style={styles.input}
            value={queueUri}
            onChangeText={setQueueUri}
            placeholder="Enter Spotify URI (e.g., spotify:track:4iV5W9uYEdYUVa79Axb7Rh)"
          />
          <Button title="Add to Queue" onPress={handleAddToQueuePress} />
          <Text style={styles.hint}>
            Tip: Find track URIs in Spotify by right-clicking a song and
            selecting "Share {">"} Copy Spotify URI"
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Playback Controls</Text>
          <View style={styles.playerInfo}>
            {playerState?.track && (
              <>
                <Text style={styles.trackInfo}>
                  {playerState.track.name} - {playerState.track.artist.name}
                </Text>
                {playerState.track.imageUri && (
                  <Image
                    source={{ uri: playerState.track.imageUri }}
                    style={styles.albumArt}
                    resizeMode="contain"
                  />
                )}
              </>
            )}
            <View style={styles.playbackControls}>
              <TouchableOpacity
                style={styles.skipButton}
                onPress={handleSkipToPreviousPress}
                disabled={!isConnected}
              >
                <Text style={styles.skipButtonText}>⏮️</Text>
              </TouchableOpacity>
              <PlayPauseButton size={60} />
              <TouchableOpacity
                style={styles.skipButton}
                onPress={handleSkipToNextPress}
                disabled={!isConnected}
              >
                <Text style={styles.skipButtonText}>⏭️</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    padding: 20,
  },
  scrollView: {
    width: "100%",
    flex: 1,
  },
  scrollViewContent: {
    alignItems: "center",
    paddingBottom: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 20,
    marginTop: 40,
  },
  section: {
    width: "100%",
    marginBottom: 20,
    padding: 15,
    borderRadius: 8,
    backgroundColor: "#f5f5f5",
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "bold",
    marginBottom: 10,
  },
  buttonRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 10,
  },
  playerInfo: {
    alignItems: "center",
    marginTop: 10,
  },
  trackInfo: {
    fontSize: 16,
    marginBottom: 15,
    textAlign: "center",
  },
  error: {
    color: "red",
    marginTop: 10,
  },
  playbackControls: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
  },
  skipButton: {
    width: 50,
    height: 50,
    justifyContent: "center",
    alignItems: "center",
    marginHorizontal: 10,
  },
  skipButtonText: {
    fontSize: 24,
  },
  albumArt: {
    width: 200,
    height: 200,
    marginBottom: 20,
    borderRadius: 8,
  },
  input: {
    width: "100%",
    height: 40,
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 5,
    marginVertical: 10,
    paddingHorizontal: 10,
  },
  hint: {
    fontSize: 12,
    color: "#666",
    marginTop: 5,
    fontStyle: "italic",
  },
});
