# WeDoBooks SDK Sample App

This is a public sample app intended to serve as inspiration for integrators.

It primarily demonstrates how to sign in with a user, check out a book, and open it using our full-screen reader or player components. You can also explore theming, localization, and several other UI configurations.

> **Note:** This app requires access to the WeDoBooks SDK backend and additional credentials to function correctly. Contact us to request access.

The `WeDoBooks SDK` includes Firebase SDK `v11.13.0`, which is statically bundled within the SDK. If your host app also uses Firebase, please notify us, as this may lead to runtime conflicts.

---

## Setup

To get started, you’ll need the following (provided by WeDoBooks upon request):

- Access to the server hosting the SDK via SPM  
  (you can use a `.netrc` file to avoid repeated login prompts in Xcode — see below).
- A demo user ID for a user in our demo backend  
  (can be provided at runtime via `Secrets.xcconfig` — see below).
- Reader credentials (key and secret)  
  (also provided via `Secrets.xcconfig`).
- The Firebase `GoogleService-Info.plist` file for the backend you intend to use.  
  The app’s bundle ID must match the one specified in this file, which must be registered in the backend.  
  Provide us with your desired bundle ID, and we’ll generate the file for you to include in your project.

---

### Secrets.xcconfig

This is the recommended way to inject the user ID, reader key, and secret mentioned above.  

The current build settings expect a file called `Secrets.xcconfig` with the following values:

```
READER_KEY = <some-key>
READER_SECRET = <some-secret>
USER_ID = <some-uid>
```

These values are injected into the `Info.plist`, which can be accessed at runtime via the main bundle.  
Create this file in the `Resources` folder and the rest should work automatically.

---

### Background Modes

To allow audio playback in the background, apps integrating the `WeDoBooks SDK` must enable the appropriate background modes.

---

## API Reference

An Xcode `.doccarchive` containing the API reference will be provided upon request.

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
  `bookOperations`, `storageOperations`, `configuration`, `events`, `localization`, `styling`, and `userOperations`.

- After setup, you can configure the SDK using these namespace properties — for example, to:
  - Apply custom styling instead of default themes
  - Change the language
  - Override localization strings

- A user must be signed in to perform book operations.  
  Use `userOperations.currentUserId()` to check whether a user is signed in.

- If no user is signed in, the sample app displays a login screen requesting a user ID.  
  If a user ID is provided via `Secrets.xcconfig`, it will be pre-filled in the input field.

- Once signed in, books can be checked out and opened via the `bookOperations` namespace.

---

## Interface Orientations

The reader and player view controllers support all orientations on `.pad` user interface idiom and portrait orientation otherwise.

---
