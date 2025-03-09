"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Authenticate = void 0;
exports.isAvailable = isAvailable;
var ExpoSpotifySDKModule_1 = require("./ExpoSpotifySDKModule");
function isAvailable() {
    return ExpoSpotifySDKModule_1.default.isAvailable();
}
function authenticateAsync(config) {
    var _a;
    if (!config.scopes || ((_a = config.scopes) === null || _a === void 0 ? void 0 : _a.length) === 0) {
        throw new Error("scopes are required");
    }
    return ExpoSpotifySDKModule_1.default.authenticateAsync(config);
}
var Authenticate = {
    authenticateAsync: authenticateAsync,
};
exports.Authenticate = Authenticate;
