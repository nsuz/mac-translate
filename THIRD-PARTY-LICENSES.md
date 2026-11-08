# Third-party licenses

## plamo-translate-desktop

`LoopDetector`, `Utf8Stream` and their tests are ports of `engine/repetition.rs` and
`engine/utf8.rs` from [tanakh/plamo-translate-desktop](https://github.com/tanakh/plamo-translate-desktop),
used under the MIT License (the project is dual-licensed MIT OR Apache-2.0).

Files:

- `TranslateCore/Sources/TranslateCore/LoopDetector.swift`
- `TranslateCore/Sources/TranslateCore/Utf8Stream.swift`
- `TranslateCore/Tests/TranslateCoreTests/LoopDetectorTests.swift`
- `TranslateCore/Tests/TranslateCoreTests/Utf8StreamTests.swift`

```
MIT License

Copyright (c) 2026 Hideyuki Tanaka

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## llama.cpp

`llama.framework`, bundled inside the app, is built from
[ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp) v0.9.0 without modification,
used under the MIT License.

```
MIT License

Copyright (c) 2023-2026 The ggml authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Noto Sans CJK JP

The letterforms in the app icon (`Translate/AppIcon.icon`) are outlines of “A” and “文” from
[Noto Sans CJK JP](https://github.com/notofonts/noto-cjk) Bold, © Google LLC, licensed under the
SIL Open Font License 1.1. The font itself is not distributed with the app.
