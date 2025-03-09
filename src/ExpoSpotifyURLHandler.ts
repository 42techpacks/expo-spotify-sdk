import * as Linking from "expo-linking";
import { EventEmitter } from "expo-modules-core";

import ExpoSpotifySDKModule from "./ExpoSpotifySDKModule";

// Event emitter for URL events
const emitter = new EventEmitter(ExpoSpotifySDKModule);

/**
 * Initializes the URL handler for Spotify callbacks
 * This should be called in your app's entry point
 */
export function initializeURLHandler(): void {
  // Handle deep links when the app is already running
  Linking.addEventListener("url", (event) => {
    console.log("Linking.addEventListener", event);
    if (event.url) {
      handleSpotifyURL(event.url);
    }
  });

  // Handle deep links when the app is launched from a URL
  Linking.getInitialURL().then((url) => {
    if (url) {
      handleSpotifyURL(url);
    }
  });
}

/**
 * Handles a Spotify URL callback
 * @param url The URL to handle
 */
function handleSpotifyURL(url: string): void {
  // Send the URL to the native module
  emitter.emit("expo-spotify-sdk-handle-url", { url });
}
