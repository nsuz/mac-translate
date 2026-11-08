# Translate

English | [日本語](README.ja.md)

On-device translation for macOS. Select text in any app, press a shortcut, and read the translation in a popover right under the selection. Nothing leaves your Mac.

Built with PLaMo. Translate runs [PLaMo 3 Translate](https://huggingface.co/pfnet/plamo-3-translate-0.8b-gguf) locally through [llama.cpp](https://github.com/ggml-org/llama.cpp), and translates among the 53 languages the model supports.

## Requirements

- macOS 26 or later on Apple Silicon
- About 600 MB of disk space for the model, downloaded once on first launch

## Install

1. Download `Translate-<version>.dmg` from [Releases](https://github.com/nsuz/mac-translate/releases) and drag Translate to Applications.
2. Open Translate. It lives in the menu bar; there is no Dock icon.

On first launch, Translate asks for Accessibility access (System Settings > Privacy & Security > Accessibility) and offers to download the model. The download screen shows the terms of the PLaMo Community License; the model is used under that license.

## Use

1. Select text in any app.
2. Press ⌥T.
3. Read the translation. Press Esc or click outside to close it. ⌘C copies the whole translation, or just the part you selected inside the popover.

Text in your primary language is translated into your secondary language; anything else is translated into the primary. The defaults are Japanese and English. Change them, the shortcut and the Japanese register (polite or plain) in Settings.

## How it works

The model runs inside the app with llama.cpp on Metal, so translating never touches the network. The only thing Translate downloads is the model, once. It does not log what it translates.

## Build from source

Xcode 27.2 or later and CMake are required.

```sh
scripts/build-llama-xcframework.sh   # builds TranslateCore/Frameworks/llama.xcframework from a pinned llama.cpp tag
open Translate.xcodeproj
```

`scripts/build-release.sh` builds a Release app, wraps it in a `.dmg` and writes `SHA256SUMS.txt` into `dist/`.

## Credits

- Translation model: [PLaMo 3 Translate](https://huggingface.co/pfnet/plamo-3-translate-0.8b-gguf) by Preferred Networks, under the [PLaMo Community License](https://plamo.preferredai.jp/info/plamo-community-license-en).
- Inference: [llama.cpp](https://github.com/ggml-org/llama.cpp), MIT License.
- App icon letterforms: [Noto Sans CJK JP](https://github.com/notofonts/noto-cjk), SIL Open Font License 1.1.
- The loop detector and the incremental UTF-8 decoder are ported from [plamo-translate-desktop](https://github.com/tanakh/plamo-translate-desktop) by Hideyuki Tanaka, MIT License. See [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md).

## License

MIT. See [LICENSE](LICENSE). Some code is ported from other projects; their notices are in [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md).
