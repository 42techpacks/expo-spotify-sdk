import { isAvailable, AppRemote, initializeURLHandler } from "expo-spotify-sdk";
import { useState, useEffect } from "react";
import { Alert, Button, StyleSheet, Text, View } from "react-native";

import { useSpotifyAppRemote } from "./src/hooks/useSpotifyAppRemote";
import { useSpotifyAuthentication } from "./src/hooks/useSpotifyAuthentication";

export default function App() {
  const [authToken, setAuthToken] = useState<string>("unknown");
  const { authenticateAsync } = useSpotifyAuthentication();
  const {
    isSpotifyAppInstalled,
    isConnected,
    connectionError,
    connectAppRemote,
    disconnectAppRemote,
    authorizeAndPlayURI,
  } = useSpotifyAppRemote();

  // Initialize URL handler
  useEffect(() => {
    initializeURLHandler();
  }, []);

  // Listen for access token received from Spotify authorization
  useEffect(() => {
    const subscription = AppRemote.addAccessTokenReceivedListener((event) => {
      console.log("Access token received:", event.accessToken);
      setAuthToken(event.accessToken);
    });

    return () => {
      subscription.remove();
    };
  }, []);

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

  async function handleConnectAppRemotePress() {
    try {
      if (authToken === "unknown") {
        Alert.alert("Error", "Please authenticate first");
        return;
      }

      const result = await connectAppRemote({ accessToken: authToken });
      console.log("App Remote connection result:", result);
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Connection Error", error.message);
      }
    }
  }

  async function handleDisconnectAppRemotePress() {
    try {
      const result = await disconnectAppRemote();
      console.log("App Remote disconnection result:", result);
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Disconnection Error", error.message);
      }
    }
  }

  async function handleAuthorizeAndPlayURIPress() {
    try {
      // Using a sample Spotify URI - you can replace this with any valid URI
      const uri = "spotify:album:1htHMnxonxmyHdKE2uDFMR";

      if (!isConnected) {
        // If not connected, use authorizeAndPlayURI which will handle authorization
        const result = await authorizeAndPlayURI(uri, { asRadio: false });
        console.log("Authorize and play URI result:", result);

        if (!result.success && !isSpotifyAppInstalled) {
          // Handle case when Spotify app is not installed
          Alert.alert(
            "Spotify Not Installed",
            "Please install the Spotify app from the App Store to continue."
          );
        }
      } else {
        // If already connected, we could handle playback directly
        // For now, we'll just show a message
        Alert.alert(
          "Already Connected",
          "App Remote is already connected. Direct playback functionality not implemented in this example."
        );
      }
    } catch (error) {
      if (error instanceof Error) {
        Alert.alert("Playback Error", error.message);
      }
    }
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Spotify SDK Example</Text>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Authentication</Text>
        <Button title="Authenticate" onPress={handleAuthenticatePress} />
        <Text>Spotify app is installed: {isAvailable() ? "yes" : "no"}</Text>
        <Text>Auth Token: {authToken.substring(0, 10)}...</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>App Remote</Text>
        <Button
          title="Connect App Remote"
          onPress={handleConnectAppRemotePress}
          disabled={isConnected}
        />
        <Button
          title="Disconnect App Remote"
          onPress={handleDisconnectAppRemotePress}
          disabled={!isConnected}
        />
        <Button
          title="Authorize and Play URI"
          onPress={handleAuthorizeAndPlayURIPress}
        />
        <Text>Spotify app is installed: {isAvailable() ? "yes" : "no"}</Text>
        <Text>App Remote connected: {isConnected ? "yes" : "no"}</Text>
        {connectionError && (
          <Text style={styles.error}>Error: {connectionError}</Text>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 20,
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
  error: {
    color: "red",
    marginTop: 10,
  },
});
