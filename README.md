# Wokyis Screensaver

Minimalist macOS screensaver-style app with three switchable visuals. Dependency-free, single binary.

![demo](docs/demo.gif)

| Topographic | Game of Life | Flip Clock |
| :---: | :---: | :---: |
| ![Topographic](docs/topographic.png) | ![Game of Life](docs/game-of-life.png) | ![Flip Clock](docs/flip-clock.png) |
| Simplex-noise contour lines. | GPU cellular automaton with trails. | Locale-aware split-flap clock. |

Hover for the picker; `Esc` to quit.

## Install

Download the latest `.dmg` from the [Releases](../../releases) page. Signed and notarized.

## Build

Requires Xcode 26+ and [xcodegen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
open WokyisScreensaver.xcodeproj   # then Cmd+R
```

`scripts/release.sh` builds a notarized DMG (needs a `Developer ID Application` cert and `NOTARY_PROFILE` notarytool credentials).

## License

MIT. Includes the Ashima / Stefan Gustavson webgl-noise port, also MIT.
