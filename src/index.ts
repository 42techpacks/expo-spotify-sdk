import {
  SpotifyConfig,
  SpotifySession,
  AuthorizeAndPlayURIResult,
  PlaybackResult,
  AppRemoteConnectionConfig,
  AppRemoteConnectionResult,
  AppRemoteDisconnectionResult,

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

function connectAppRemoteAsync(
  config: AppRemoteConnectionConfig,
): Promise<AppRemoteConnectionResult> {
  if (!config.accessToken) {
    throw new Error("accessToken is required");
  }

  return ExpoSpotifySDKModule.connectAppRemoteAsync(config);
}

function disconnectAppRemoteAsync(): Promise<AppRemoteDisconnectionResult> {
  return ExpoSpotifySDKModule.disconnectAppRemoteAsync();
}

/**
 * Starts or resumes playback on the active device
 * @returns Promise that resolves with a success boolean
 */
function playAsync(): Promise<PlaybackResult> {
  return ExpoSpotifySDKModule.playAsync();
}

/**
 * Pauses playback on the active device
 * @returns Promise that resolves with a success boolean
 */
function pauseAsync(): Promise<PlaybackResult> {
  return ExpoSpotifySDKModule.pauseAsync();
}

const Authenticate = {
  authenticateAsync,
};

const AppRemote = {
  authorizeAndPlayURIAsync,
  isAppRemoteConnected,
  playAsync,
  pauseAsync,
  connectAppRemoteAsync,
  disconnectAppRemoteAsync,
};

export { isAvailable, Authenticate, AppRemote };
