_This document explains how the application works and how the code is organized. It will change over time. If you notice inconsistencies, feel free to open an issue or pull request._

# Structure

The Helium 3 code is arranged as follows:

```
helium-3
├── .gitignore
├── elm.json
├── package-lock.json
├── package.json
├── docs                  Folder with documentation on the game and application
├── elm-stuff             Cached Elm packages and compiled code (not tracked by Git)
├── node_modules          Cached NPM packages (not tracked by Git)
└── src                   Folder that holds the code for the application
    └── Page              Each page roughly corresponds to a URL segment
        └── Game.elm      The main module for the page where you play the game
```
