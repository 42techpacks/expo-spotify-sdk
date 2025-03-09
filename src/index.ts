import { EventEmitter, Subscription } from "expo-modules-core";

import {
  SpotifyConfig,
  SpotifySession,
  AppRemoteConnectionConfig,
  AppRemoteConnectionResult,
  AppRemoteDisconnectionResult,
  AppRemoteConnectedEvent,
  AppRemoteConnectionFailureEvent,
  AppRemoteDisconnectedEvent,
  AuthorizeAndPlayURIOptions,
  AuthorizeAndPlayURIResult,
  AccessTokenReceivedEvent,
} from "./ExpoSpotifySDK.types";
import ExpoSpotifySDKModule from "./ExpoSpotifySDKModule";
import { initializeURLHandler } from "./ExpoSpotifyURLHandler";

// Event emitter for App Remote events
const emitter = new EventEmitter(ExpoSpotifySDKModule);

function isAvailable(): boolean {
  return ExpoSpotifySDKModule.isAvailable();
}

function isSpotifyAppInstalled(): boolean {
  return ExpoSpotifySDKModule.isSpotifyAppInstalled();
}

function isAppRemoteConnected(): boolean {
  return ExpoSpotifySDKModule.isAppRemoteConnected();
}

function authenticateAsync(config: SpotifyConfig): Promise<SpotifySession> {
  if (!config.scopes || config.scopes?.length === 0) {
    throw new Error("scopes are required");
  }

  return ExpoSpotifySDKModule.authenticateAsync(config);
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
 * Authorizes with Spotify and immediately starts playback of the provided URI
 * @param uri The Spotify URI to play
 * @param options Optional parameters including asRadio
 * @returns Promise that resolves with a success boolean
 */
function authorizeAndPlayURIAsync(
  uri: string,
  options?: AuthorizeAndPlayURIOptions,
): Promise<AuthorizeAndPlayURIResult> {
  if (!uri) {
    throw new Error("uri is required");
  }

  return ExpoSpotifySDKModule.authorizeAndPlayURIAsync({
    uri,
    asRadio: options?.asRadio || false,
  });
}

/**
 * Handles a URL received from Spotify after authorization
 * @param url The URL to handle
 * @returns Boolean indicating if the URL was successfully handled
 */
function handleURL(url: string): boolean {
  return ExpoSpotifySDKModule.handleURL(url);
}

// Event listeners
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

/**
 * Adds a listener for when an access token is received from Spotify
 * @param listener The function to call when an access token is received
 * @returns A subscription that can be used to remove the listener
 */
function addAccessTokenReceivedListener(
  listener: (event: AccessTokenReceivedEvent) => void,
): Subscription {
  return emitter.addListener("onAccessTokenReceived", listener);
}

const Authenticate = {
  authenticateAsync,
};

const AppRemote = {
  connectAppRemoteAsync,
  disconnectAppRemoteAsync,
  authorizeAndPlayURIAsync,
  handleURL,
  isAppRemoteConnected,
  addAppRemoteConnectedListener,
  addAppRemoteConnectionFailureListener,
  addAppRemoteDisconnectedListener,
  addAccessTokenReceivedListener,
};

export {
  isAvailable,
  isSpotifyAppInstalled,
  Authenticate,
  AppRemote,
  initializeURLHandler,
};
