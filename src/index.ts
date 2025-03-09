import {
  SpotifyConfig,
  SpotifySession,
  AuthorizeAndPlayURIResult,
} from "./ExpoSpotifySDK.types";
import ExpoSpotifySDKModule from "./ExpoSpotifySDKModule";

function isAvailable(): boolean {
  return ExpoSpotifySDKModule.isAvailable();
}

function authenticateAsync(config: SpotifyConfig): Promise<SpotifySession> {
  if (!config.scopes || config.scopes?.length === 0) {
    throw new Error("scopes are required");
  }

  return ExpoSpotifySDKModule.authenticateAsync(config);
}

/**
 * Authorizes with Spotify and immediately starts playback of the provided URI
 * @param uri The Spotify URI to play
 * @returns Promise that resolves with a success boolean
 */
function authorizeAndPlayURIAsync(
  uri: string,
): Promise<AuthorizeAndPlayURIResult> {
  if (!uri) {
    throw new Error("uri is required");
  }

  return ExpoSpotifySDKModule.authorizeAndPlayURIAsync({
    uri,
  });
}

function isAppRemoteConnected(): boolean {
  return ExpoSpotifySDKModule.isAppRemoteConnected();
}

const Authenticate = {
  authenticateAsync,
};

const AppRemote = {
  authorizeAndPlayURIAsync,
  isAppRemoteConnected,
};

export { isAvailable, Authenticate, AppRemote };
