# Translate

[English](README.md) | 日本語

macOS のためのオンデバイス翻訳。どのアプリでもテキストを選んでショートカットを押すと、選択範囲のすぐ下にポップオーバーで訳文が出ます。文章が Mac の外に出ることはありません。

Built with PLaMo. Translate は [PLaMo 3 Translate](https://huggingface.co/pfnet/plamo-3-translate-0.8b-gguf) を [llama.cpp](https://github.com/ggml-org/llama.cpp) でローカルに動かし、モデルが対応する 53 言語の間で翻訳します。

## 動作環境

- Apple シリコンの Mac、macOS 26 以降
- モデル用に約 600 MB の空き容量（初回起動時に一度だけダウンロードします）

## インストール

1. [Releases](https://github.com/nsuz/mac-translate/releases) から `Translate-<version>.dmg` をダウンロードし、Translate を Applications にドラッグします。
2. Translate を起動します。メニューバーに常駐し、Dock にはアイコンが出ません。

初回起動時に、アクセシビリティの許可（システム設定 > プライバシーとセキュリティ > アクセシビリティ）を求め、モデルのダウンロードを案内します。ダウンロード画面には PLaMo Community License の要点が表示されます。モデルはこのライセンスのもとで使います。

## 使い方

1. どのアプリでもテキストを選びます。
2. ⌥T を押します。
3. 訳文を読みます。Esc か外側のクリックで閉じます。⌘C で訳文全体を、ポップオーバーの中で選択していればその部分だけをコピーします。

優先する言語の文章は 2 番目の言語に、それ以外は優先する言語に翻訳します。既定は日本語と英語です。言語、ショートカット、日本語の文体（敬体・常体）は設定で変えられます。

## 仕組み

モデルはアプリの中で llama.cpp を使って Metal 上で動くので、翻訳のときにネットワークを使うことはありません。ネットワークを使うのは、最初にモデルをダウンロードする一度だけです。翻訳した文章を記録することもありません。

## ソースからビルド

Xcode 27.2 以降と CMake が必要です。

```sh
scripts/build-llama-xcframework.sh   # 固定したタグの llama.cpp から TranslateCore/Frameworks/llama.xcframework を作ります
open Translate.xcodeproj
```

`scripts/build-release.sh` は Release ビルドの app を `.dmg` にまとめ、`SHA256SUMS.txt` とともに `dist/` に書き出します。

## クレジット

- 翻訳モデル: Preferred Networks の [PLaMo 3 Translate](https://huggingface.co/pfnet/plamo-3-translate-0.8b-gguf)。[PLaMo Community License](https://plamo.preferredai.jp/info/plamo-community-license-ja) のもとで使用しています。
- 推論: [llama.cpp](https://github.com/ggml-org/llama.cpp)。MIT License。
- アプリアイコンの字形: [Noto Sans CJK JP](https://github.com/notofonts/noto-cjk)。SIL Open Font License 1.1。
- ループ検出器と逐次 UTF-8 デコーダは Hideyuki Tanaka さんの [plamo-translate-desktop](https://github.com/tanakh/plamo-translate-desktop)（MIT License）から移植しました。[THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md) を参照してください。

## ライセンス

MIT。[LICENSE](LICENSE) を参照してください。一部のコードは他のプロジェクトから移植しており、その表示は [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md) にあります。
