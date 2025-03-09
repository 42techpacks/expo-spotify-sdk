export interface SpotifySession {
  accessToken: string;
  refreshToken: string;
  expirationDate: number;
  scopes: SpotifyScope[];
}

export interface SpotifyConfig {
  scopes: SpotifyScope[];
  tokenSwapURL?: string;
  tokenRefreshURL?: string;
}

// export interface AndroidSpotifyConfig extends SpotifyConfig {
//   responseType: "token" | "code";
// }

export type SpotifyScope =
  | "ugc-image-upload"
  | "user-read-playback-state"
  | "user-modify-playback-state"
  | "user-read-currently-playing"
  | "app-remote-control"
  | "streaming"
  | "playlist-read-private"
  | "playlist-read-collaborative"
  | "playlist-modify-private"
  | "playlist-modify-public"
  | "user-follow-modify"
  | "user-follow-read"
  | "user-top-read"
  | "user-read-recently-played"
  | "user-library-modify"
  | "user-library-read"
  | "user-read-email"
  | "user-read-private";

export interface AuthorizeAndPlayURIResult {
  success: boolean;
}

export interface PlaybackResult {
  success: boolean;
}

export interface AppRemoteConnectionConfig {
  accessToken: string;
}

export interface AppRemoteConnectionResult {
  connected: boolean;
}

export interface AppRemoteDisconnectionResult {
  disconnected: boolean;
}

export type ExpoSpotifySDKModuleEvents = {
  onAppRemoteConnected: (event: AppRemoteConnectedEvent) => void;
  onAppRemoteDisconnected: (event: AppRemoteDisconnectedEvent) => void;
  onAppRemoteConnectionFailure: (
    event: AppRemoteConnectionFailureEvent,
  ) => void;
};

export type AppRemoteConnectedEvent = {
  connected: boolean;
};

export type AppRemoteDisconnectedEvent = {
  error: string;
};

export type AppRemoteConnectionFailureEvent = {
  error: string;
};
