import { NativeModule, requireNativeModule } from "expo-modules-core";

import { ExpoSpotifySDKModuleEvents } from "./ExpoSpotifySDK.types";

declare class ExpoSpotifySDKModule extends NativeModule<ExpoSpotifySDKModuleEvents> {}

const ExpoSpotifySDK =
  requireNativeModule<ExpoSpotifySDKModule>("ExpoSpotifySDK");

// It loads the native module object from the JSI or falls back to
// the bridge module (from NativeModulesProxy) if the remote debugger is on.
export default ExpoSpotifySDK;
