# WeDoBooks SDK Sample App

This is a public sample app intended to serve as inspiration for integrators.

It primarily demonstrates how to sign in with a user, check out a book, and open it using our full-screen reader or player components. You can also explore theming, localization, and several other UI configurations.

> **Note:** This app requires access to the WeDoBooks SDK backend and additional credentials to function correctly. Contact us to request access.

---

## Documentation

We currently have 2 main pieces of documentation apart from the sample app code itself:

- [iOS introduction.pdf](./iOS%20SDK%20Introduction.pdf)
- [Zipped Apple docs](./WeDoBooksSDK.doccarchive.zip)

## Setup

To get started, you’ll need the following (provided by WeDoBooks upon request):

- Access to the server hosting the SDK via SPM  
  (you can use a `.netrc` file to avoid repeated login prompts in Xcode — see below).
- A demo user ID for a user in our demo backend  
  (typed into the field on the app’s login screen at runtime — see below).
- Reader credentials (key and secret)
  (provided via `Secrets.xcconfig` — see below).
- Custom token URL which is used to get a sign in token for the demo user until you own backend is able to provide it for you.
  (also provided via `Secrets.xcconfig`).
- The Firebase `GoogleService-Info.plist` file for the backend you intend to use.  
  The app’s bundle ID must match the one specified in this file, which must be registered in the backend.  
  Provide us with your desired bundle ID, and we’ll generate the file for you to include in your project.  
  Drop it in the `Resources` folder and tick the `WeDoBooksSDKSample` target in Xcode’s File Inspector — these files are gitignored, so the project cannot list them for you, and the app needs the file *in the bundle* at runtime.
- The name of the Firebase file above, filled into `Sources/Environments.swift` — see below.
- ISBNs from the catalog of that backend, typed into the app at runtime (the Checkouts, Reservations and headless player tabs each have an ISBN field).

---

### Secrets.xcconfig

This is the recommended way to inject the reader key and secret and the custom token URL mentioned above.  

The current build settings expect a file called `Secrets.xcconfig` with the following values:

```
READER_KEY = <some-key>
READER_SECRET = <some-secret>
CUSTOM_TOKEN_URL = <some-url>
```

(`Resources/Info.plist` still declares a `USER_ID` key fed from this file, but nothing reads it any more — the demo user ID is typed on the login screen instead.)

These values are injected into the `Info.plist`, which can be accessed at runtime via the main bundle.  
Create this file in the `Resources` folder and the rest should work automatically.

---

### Environments.swift

The app can be pointed at several backends. They are listed in `Sources/Environments.swift`, and the login screen has an environment picker populated from that list:

```swift
enum Environments {
    static let all: [Environment] = [
        Environment(
            id: "demo-streaming",
            displayName: "Demo (streaming)",
            mode: .streaming,
            firebaseFile: "GoogleService-Info-demo.plist",
            tokenUrl: "$(CUSTOM_TOKEN_URL)"
        ),
    ]
}
```

- `id` — used to remember the picked environment across launches; must be unique.
- `displayName` — the name shown in the picker.
- `mode` — `.streaming` or `.library` (a `WeDoBooksFacade.Mode`).
- `firebaseFile` — name of the `GoogleService-Info-*.plist` in the main bundle to configure the SDK with.
- `tokenUrl` — the custom token endpoint the demo user is signed in through. Every value except `id` may be written as `"$(SOME_KEY)"` to read it from the `Info.plist` at runtime instead, which is how the committed file stays free of credentials while `Secrets.xcconfig` supplies the real ones. Values resolved that way are percent-decoded, since an xcconfig cannot hold a raw `//`.

Those five arguments are the whole structure — an environment describes *which backend* to talk to, and nothing else. The demo user ID and the ISBNs are typed into the app at runtime instead: the user ID on the login screen, the ISBNs in the Checkouts, Reservations and headless player tabs. Neither is persisted, so both need retyping after a relaunch.

The file ships with a single `"TODO"` placeholder entry — fill in one entry per backend you have access to, and delete the ones you don't need. The first entry is the default until an environment is picked.

Note that `CUSTOM_TOKEN_URL` belongs to *one* backend. A second environment therefore needs its own token endpoint: add it under a new name in `Secrets.xcconfig`, expose that name in `Resources/Info.plist` the same way the existing one is, and reference it from that environment’s entry (for example `tokenUrl: "$(CUSTOM_TOKEN_URL_LIBRARY)"`). Signing in also needs a user ID that exists in *that* backend, so remember to type the matching one after switching.

Because `WeDoBooksFacade.setup(...)` may only be called once per launch, picking a different environment persists the choice and closes the app. iOS gives an app no way to relaunch itself, so `AppRestarter` schedules a local notification on the way out — tap it to reopen the app against the new environment, or open the app yourself. The first switch asks for notification permission; declining it just means the app closes without leaving anything to tap.

---

### Background Modes

To allow audio playback in the background, apps integrating the `WeDoBooks SDK` must enable the appropriate background modes.

---

## API Reference

Can be found in the zip file `WeDoBooksSDK.doccarchive.zip` in the repo root, which contains the matching doccarchive reference for the SDK APIs.

---

## Backend-to-Backend Integration

In order to sign a user in to the WeDoBooks SDK you need a so-called custom token.
In a production environment, this token should be obtained through backend-to-backend integration and passed to the app.

For demo purposes, this app uses a demo backend endpoint, allowing it to function without backend integration.  
Refer to `LoginViewController.obtainDemoUserTokenAndSignIn()` for the relevant call.

---

## Overview of the App

Working with the SDK generally follows this pattern:

- The `WeDoBooksFacade` singleton is the entry point to all SDK functionality:  
  ```swift
  WeDoBooksFacade.shared
  ```

- Before using any SDK features, you must call the `setup` method on the singleton instance.  
  This should only be done once; calling it multiple times will result in an error.

- SDK functionality is organized into namespaces, accessible via properties on the `WeDoBooksFacade` instance.  
  Current namespaces include:  
  `bookOperations`, `storageOperations`, `configuration`, `events`, `headlessAudioPlayer`, `localization`, `styling`, and `userOperations`.

- After setup, you can configure the SDK using these namespace properties — for example, to:
  - Apply custom styling instead of default themes
  - Change the language
  - Override localization strings

- A user must be signed in to perform book operations.  
  Use `userOperations.currentUserId()` to check whether a user is signed in.

- If no user is signed in, the sample app displays a login screen with a field for the demo user ID and a sign-in button,  
  plus an environment picker for switching backend (see `Environments.swift` above).

- Once signed in, books can be checked out and opened via the `bookOperations` namespace.

---

## Interface Orientations

The reader and player view controllers support all orientations on `.pad` user interface idiom and portrait orientation otherwise.

---
