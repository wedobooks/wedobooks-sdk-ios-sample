# WeDoBooks SDK Sample App

Public sample app as inspiration for integrators. 

It mainly demonstrates how to sign in with user, checkout a book and open it with our full screen reader or player components. It's also possible to play around with theming, localization and a few other configurations of the UI.

This app requires a WeDoBooks SDK backend and other credentials to function properly. Get in touch to obtain access.

The WeDoBooksSDK uses the Firebase SDK v11.13.0 which is statically bundled inside the SDK. If you use Firebase in the host app please let us know as this could potentially present some challenges at runtime.

## Setup

In order to get up and running you need the following (which will be delivered by WeDoBooks when requested):

- Access to the server that's delivering the SDK through SPM (can be used in a .netrc file to avoid entering in Xcode on every download - see below).
- A demo user id of a user in our demo backend (can be delivered to the runtime through Secrets.xcconfig - see below).
- Credentials (key and secret) to the reader component (can be delivered to the runtime through Secrets.xcconfig - see below).
- Firebase info plist file of the backend you want to use. The bundle id of the app must match the bundle id in this file which must exists as a defined app in the backend. Let us know the desired bundle id and we will produce this file for you and it needs to be added to the project.

### Secrets.xcconfig

This the recommended way to inject the user id, reader key and secret mentioned above, but of course, feel free to do it in another way.

The current build settings look for a file called Secrets.xcconfig and expects these values:

```
READER_KEY = <some-key>
READER_SECRET = <some-secret>
USER_ID = <some-uid>
```

These values are then loaded into the Info.plist file which can be accessed at runtime through the main bundle. Create this file with the values in the Resources folder and the rest should take care of itself.

### Background modes

In order to be allowed to play audio in the background any app the integrates with the WeDoBooks SDK

## API reference

We will deliver an Xcode doccarchive with the API reference upon request.

## Backend to backend integration

In order to sign a user in to the WeDoBooks SDK you need a so-called custom token. In a real app this would have to be obtained through a backend to backend integration and passed to the app. For demo purposes this app utilizes a demo backend endpoint in order to function without having the backend to backend integration setup. See `LoginViewController.obtainDemoUserTokenAndSignIn()` for the call to the demo backend endpoint. If you're using your own dedicated instance of the SDK backend, then the URL needs to change. Talk to us to get the proper endpoint to call here.

## Overview of the app

Working with the SDK follows this outline:

- The WeDoBooksFacade singleton is the gateway to all the SDK functionality and can be accessed like this `WeDoBooksFacade.shared` 
- Before doing anything else with the SDK you must call the `setup` method on the WeDoBooksFacade singleton instance. This should only be called once and will throw an error if it's called more than once.
- All other functionality in the SDK is grouped in namespaces which can be accessed through properties on the WeDoBooksFacade instance. At the time of writing these namespaces exist: `bookOperations`, `storageOperations`, `configuration`, `events`, `localization`, `styling` and `userOperations`.  
- After setup you can configure the SDK through these namespace properties if you for example want to use different styling that the default themes, change language, override some localizations, etc. 
- In order to do any book operations a user needs to be signed in. This can be checked using the `currentUserId()` method on the `userOperations` namespace property.
- If no user is signed in the sample app displays a login screen that asks for a user id. If there's a user id provided through the Secrets.xcconfig file as described above, then that user id is prefilled in the text field as a shortcut.
- After having signed in then you can checkout and open books through the `bookOperations` namespace property.

## Interface orientations

The reader and player view controllers support all orientations on `.pad` user interface idiom and portrait orientation otherwise.
