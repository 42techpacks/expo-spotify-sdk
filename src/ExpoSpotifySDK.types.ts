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

export interface AppRemoteConnectionConfig {
  accessToken: string;
}

export interface AppRemoteConnectionResult {
  connected: boolean;
}

export interface AppRemoteDisconnectionResult {
  disconnected: boolean;
}

export interface AuthorizeAndPlayURIOptions {
  asRadio?: boolean;
}

export interface AuthorizeAndPlayURIResult {
  success: boolean;
}

// export interface AndroidSpotifyConfig extends SpotifyConfig {
//   responseType: "token" | "code";
// }

export interface PlayerState {
  name: string;
  uri: string;
  duration: number;
  isPaused: boolean;
  playbackPosition: number;
  playbackSpeed: number;
  artist?: {
    name: string;
    uri: string;
  };
  album?: {
    name: string;
    uri: string;
  };
}

export interface ImageSize {
  width: number;
  height: number;
}

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

export interface AppRemoteConnectedEvent {
  connected: boolean;
}

export interface AppRemoteConnectionFailureEvent {
  error: string;
}

export interface AppRemoteDisconnectedEvent {
  error?: string;
}

export interface AccessTokenReceivedEvent {
  accessToken: string;
}
