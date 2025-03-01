import { SpotifyConfig, SpotifySession, PlayerState, ImageSize } from "./ExpoSpotifySDK.types";
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

// App Remote functions
async function connectToAppRemote(accessToken: string): Promise<boolean> {
  return ExpoSpotifySDKModule.connectToAppRemote(accessToken);
}

async function disconnectFromAppRemote(): Promise<boolean> {
  return ExpoSpotifySDKModule.disconnectFromAppRemote();
}

// Playback control functions
async function play(uri: string): Promise<boolean> {
  return ExpoSpotifySDKModule.play(uri);
}

async function resume(): Promise<boolean> {
  return ExpoSpotifySDKModule.resume();
}

async function pause(): Promise<boolean> {
  return ExpoSpotifySDKModule.pause();
}

async function skipToNext(): Promise<boolean> {
  return ExpoSpotifySDKModule.skipToNext();
}

async function skipToPrevious(): Promise<boolean> {
  return ExpoSpotifySDKModule.skipToPrevious();
}

// Player state functions
async function getPlayerState(): Promise<PlayerState> {
  return ExpoSpotifySDKModule.getPlayerState();
}

async function getAlbumArt(imageSize: ImageSize): Promise<string> {
  return ExpoSpotifySDKModule.getAlbumArt(imageSize);
}

async function subscribeToPlayerState(): Promise<boolean> {
  return ExpoSpotifySDKModule.subscribeToPlayerState();
}

// Event listener for player state changes
function addPlayerStateListener(callback: (playerState: PlayerState) => void): () => void {
  const subscription = ExpoSpotifySDKModule.addListener('onPlayerStateChanged', callback);
  return () => subscription.remove();
}

const Authenticate = {
  authenticateAsync,
};

const Player = {
  connectToAppRemote,
  disconnectFromAppRemote,
  play,
  resume,
  pause,
  skipToNext,
  skipToPrevious,
  getPlayerState,
  getAlbumArt,
  subscribeToPlayerState,
  addPlayerStateListener,
};

export { isAvailable, Authenticate, Player };
