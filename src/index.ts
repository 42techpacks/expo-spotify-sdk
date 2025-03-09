import { EventEmitter, Subscription } from "expo-modules-core";

import {
  SpotifyConfig,
  SpotifySession,
  AuthorizeAndPlayURIResult,
  PlaybackResult,
  AppRemoteConnectionConfig,
  AppRemoteConnectionResult,
  AppRemoteDisconnectionResult,
  AppRemoteConnectionFailureEvent,
  AppRemoteDisconnectedEvent,
  AppRemoteConnectedEvent,
  PlayerState,
  PlayerStateResult,
  PlayerStateSubscriptionResult,
  PlayerStateChangedEvent,
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

/**
 * Gets the current player state
 * @returns Promise that resolves with the current player state
 */
function getPlayerStateAsync(): Promise<PlayerStateResult> {
  return ExpoSpotifySDKModule.getPlayerStateAsync();
}

/**
 * Subscribes to player state changes
 * @returns Promise that resolves with a success boolean
 */
function subscribeToPlayerStateAsync(): Promise<PlayerStateSubscriptionResult> {
  return ExpoSpotifySDKModule.subscribeToPlayerStateAsync();
}

/**
 * Unsubscribes from player state changes
 * @returns Promise that resolves with a success boolean
 */
function unsubscribeFromPlayerStateAsync(): Promise<PlayerStateSubscriptionResult> {
  return ExpoSpotifySDKModule.unsubscribeFromPlayerStateAsync();
}

// Event listeners
const emitter = new EventEmitter(ExpoSpotifySDKModule);

function addAppRemoteConnectedListener(
  listener: (event: AppRemoteConnectedEvent) => void,
): Subscription {
  return emitter.addListener("onAppRemoteConnected", listener);
}

function addAppRemoteConnectionFailureListener(
  listener: (event: AppRemoteConnectionFailureEvent) => void,
): Subscription {
  return emitter.addListener("onAppRemoteConnectionFailure", listener);
}

function addAppRemoteDisconnectedListener(
  listener: (event: AppRemoteDisconnectedEvent) => void,
): Subscription {
  return emitter.addListener("onAppRemoteDisconnected", listener);
}

function addPlayerStateChangedListener(
  listener: (event: PlayerStateChangedEvent) => void,
): Subscription {
  return emitter.addListener("onPlayerStateChanged", listener);
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
  addAppRemoteConnectedListener,
  addAppRemoteConnectionFailureListener,
  addAppRemoteDisconnectedListener,
  getPlayerStateAsync,
  subscribeToPlayerStateAsync,
  unsubscribeFromPlayerStateAsync,
  addPlayerStateChangedListener,
};

export { isAvailable, Authenticate, AppRemote };
